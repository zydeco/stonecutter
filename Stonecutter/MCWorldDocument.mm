//
//  Document.m
//  Stonecutter
//
//  Created by Jesús A. Álvarez on 15/02/2018.
//  Copyright © 2018 namedfork. All rights reserved.
//

#import "MCWorldDocument.h"
#include "leveldb/db.h"
#include "leveldb/env.h"
#include "leveldb/cache.h"
#include "leveldb/filter_policy.h"
#include "leveldb/slice.h"
#include "leveldb/iterator.h"
#include "leveldb/write_batch.h"
#include "leveldb/decompress_allocator.h"
#include "leveldb/zlib_compressor.h"
#include "libzippp.h"
#include "nbt_tags.h"
#include "libnbtplusplus/include/io/stream_reader.h"
#include <fstream>
#include <iostream>

#import "AppDelegate.h"
#import "ProgressWindow.h"
#import "UnpackWorldOperation.h"
#import "PackWorldOperation.h"
#import "PerformActionOperation.h"
#import "MCPlayer.h"
#import "DocumentController.h"
#import "PlayersWindowController.h"

using namespace libzippp;
using namespace leveldb;

NSErrorDomain LevelDBErrorDomain = @"LevelDBErrorDomain";

@interface MCWorldDocument () <NSTableViewDelegate, NSTextFieldDelegate>

@end

@implementation MCWorldDocument
{
    NSURL *worldDirectory;
    UnpackWorldOperation *unpackOperation;
    PackWorldOperation *packOperation;
    PerformActionOperation *loadWorldOperation;
    DB *db;
    NSArray<MCPlayer*> *players;
    NSDictionary *levelDat;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.hasUndoManager = NO;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cleanupTemporaryFiles) name:NSApplicationWillTerminateNotification object:NSApp];
    }
    return self;
}

- (BOOL)isEntireFileLoaded {
    return NO;
}

- (NSString *)windowNibName {
    return @"Document";
}

- (void)makeWindowControllers {
    [super makeWindowControllers];
    self.windowControllers.firstObject.shouldCloseDocument = YES;
}

#pragma mark - Progress UI

- (void)showProgressForWorldOperation:(WorldOperation*)operation {
    if (!operation.isFinished) {
        _progressWindow.progress = operation.progress;
        _progressWindow.progresLabel.stringValue = operation.localizedName;
        [operation addObserver:self forKeyPath:@"finished" options:0 context:NULL];
        [self.windowForSheet beginSheet:_progressWindow completionHandler:^(NSModalResponse returnCode) {
            if (operation.error) {
                [self giveUpWithError:operation.error];
            } else if (operation == self->unpackOperation) {
                [self openWorld];
            }
        }];
    } else if (operation.error) {
        [self giveUpWithError:operation.error];
    } else if (operation.isFinished && operation == unpackOperation) {
        // so fast?
        [self openWorld];
    }
}

- (void)giveUpWithError:(NSError*)error {
    if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:_cmd withObject:error waitUntilDone:NO];
        return;
    }
    NSAlert *alert = [NSAlert alertWithError:error];
    if (self.windowForSheet.attachedSheet) {
        alert.alertStyle = NSAlertStyleWarning;
    }
    [alert beginSheetModalForWindow:self.windowForSheet completionHandler:^(NSModalResponse returnCode) {
        [self close];
    }];
}

- (void)endProgressWithResponseCode:(NSModalResponse)response {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.windowForSheet endSheet:self->_progressWindow returnCode:response];
    });
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([object isKindOfClass:[WorldOperation class]] && [keyPath isEqualToString:@"finished"]) {
        [object removeObserver:self forKeyPath:keyPath];
        [self endProgressWithResponseCode:NSModalResponseOK];
    }
}

#pragma mark - Packing/Unpacking

- (BOOL)readFromURL:(NSURL *)url ofType:(NSString *)typeName error:(NSError * _Nullable __autoreleasing *)outError {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    // check zip
    // might not have directory entries, so enumerate entries
    ZipArchive zf(url.fileSystemRepresentation);
    zf.open(ZipArchive::READ_ONLY);
    BOOL isValidWorldZip = NO;
    if (zf.hasEntry("level.dat")) {
        for (libzippp_int64 i = 0; i < zf.getNbEntries(); i++) {
            ZipEntry entry = zf.getEntry(i);
            if (entry.getName().find("db/") == 0) {
                isValidWorldZip = YES;
                break;
            }
        }
    }
    if (!isValidWorldZip) {
        // doesn't seem like a world
        if (outError) {
            *outError = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileReadCorruptFileError userInfo:@{NSLocalizedFailureReasonErrorKey: @"No db or level.dat"}];
        }
        return NO;
    }
    zf.close();
    
    // create directory
    if (worldDirectory != nil) {
        if (loadWorldOperation.isExecuting) {
            [loadWorldOperation cancel];
            [loadWorldOperation waitUntilFinished];
        }
        if (db) {
            delete db;
            db = nullptr;
        }
        [self cleanupTemporaryFiles];
    } else {
        worldDirectory = [[AppDelegate sharedInstance].documentController urlForUnpackingWorld:url];
    }
    if (worldDirectory == nil) {
        return NO;
    }
    if (![fileManager createDirectoryAtURL:worldDirectory withIntermediateDirectories:YES attributes:nil error:outError]) {
        return NO;
    }
    NSLog(@"opening into %@", worldDirectory.path);
    
    // extract zip in background
    unpackOperation = [UnpackWorldOperation new];
    unpackOperation.source = url;
    unpackOperation.destination = worldDirectory;
    [unpackOperation performSelectorInBackground:@selector(start) withObject:nil];
    [self performSelector:@selector(showProgressForWorldOperation:) withObject:unpackOperation afterDelay:0.1];
    [self.tabView selectFirstTabViewItem:nil];
    
    return YES;
}

- (BOOL)canAsynchronouslyWriteToURL:(NSURL *)url ofType:(NSString *)typeName forSaveOperation:(NSSaveOperationType)saveOperation {
    return YES;
}

- (BOOL)writeToURL:(NSURL *)url ofType:(NSString *)typeName error:(NSError * _Nullable __autoreleasing *)outError {
    [self unblockUserInteraction];
    
    packOperation = [PackWorldOperation new];
    packOperation.source = worldDirectory;
    packOperation.destination = url;
    [self performSelectorOnMainThread:@selector(showProgressForWorldOperation:) withObject:packOperation waitUntilDone:NO];
    [packOperation start];
    [packOperation waitUntilFinished];
    
    if (outError && packOperation.error) {
        *outError = packOperation.error;
    }
    return packOperation.error == nil;
}

- (void)close {
    if (loadWorldOperation.isExecuting) {
        [loadWorldOperation cancel];
        [loadWorldOperation waitUntilFinished];
    }
    if (db) {
        delete db;
        db = nullptr;
    }
    [self cleanupTemporaryFiles];
    [super close];
}

- (void)cleanupTemporaryFiles {
    if (worldDirectory) {
        [[NSFileManager defaultManager] removeItemAtURL:worldDirectory error:NULL];
    }
}

#pragma mark - World

- (BOOL)checkOk:(Status)status {
    if (status.ok()) {
        return YES;
    } else {
        NSError *error = [NSError errorWithDomain:LevelDBErrorDomain code:status.code() userInfo:@{NSLocalizedFailureReasonErrorKey: @(status.ToString().c_str())}];
        [self giveUpWithError:error];
        return NO;
    }
}

- (void)openWorld {
    Options options;
    options.filter_policy = NewBloomFilterPolicy(10);
    options.block_cache = NewLRUCache(40 * 1024 * 1024);
    options.write_buffer_size = 4 * 1024 * 1024;
    options.compressors[0] = new ZlibCompressorRaw(-1);
    options.compressors[1] = new ZlibCompressor();
    
    [self.loadingWorldIndicator startAnimation:nil];
    NSURL *dbDirectory = [worldDirectory URLByAppendingPathComponent:@"db"];
    if ([self checkOk: DB::Open(options, dbDirectory.fileSystemRepresentation, &db)]) {
        [self loadWorld];
    }
}

- (void)loadWorld {
    [self.loadingWorldIndicator startAnimation:nil];
    [self.tabView selectTabViewItemAtIndex:0];
    
    loadWorldOperation = [PerformActionOperation operationWithTarget:self action:@selector(loadWorld:)];
    [loadWorldOperation performSelectorInBackground:@selector(start) withObject:nil];
}

- (void)loadWorld:(NSOperation*)operation {
    ReadOptions readOptions;
    readOptions.decompress_allocator = new DecompressAllocator();
    readOptions.snapshot = self->db->GetSnapshot();
    Iterator *it = self->db->NewIterator(readOptions);
    NSMutableArray<MCPlayer*> *newPlayers = [NSMutableArray arrayWithCapacity:4];
    NSMutableSet<NSValue*> *overworldChunks = [NSMutableSet setWithCapacity:128];
    NSMutableSet<NSValue*> *netherChunks = [NSMutableSet setWithCapacity:128];
    NSMutableSet<NSValue*> *endChunks = [NSMutableSet setWithCapacity:128];
    
    // go through leveldb
    for (it->SeekToFirst(); it->Valid(); it->Next()) {
        if (operation.cancelled) {
            break;
        }
        size_t keySize = it->key().size();
        
        // player
        BOOL isLocalPlayer = keySize == 13 && memcmp(it->key().data(), "~local_player", 13) == 0;
        BOOL isOtherPlayer = keySize == 43 && strncmp(it->key().data(), "player_", 7) == 0;
        if (isLocalPlayer || isOtherPlayer) {
            NSString *playerKey = @(it->key().ToString().c_str());
            NSData *playerData = [NSData dataWithBytes:it->value().data() length:it->value().size()];
            [newPlayers addObject:[[MCPlayer alloc] initWithKey:playerKey data:playerData]];
        }
        
        // chunk
        else if (keySize == 9 || keySize == 10 || keySize == 13 || keySize == 14) {
            const char * keyData = it->key().data();
            int32_t x = OSReadLittleInt32(keyData, 0);
            int32_t y = OSReadLittleInt32(keyData, 4);
            ChunkPos pos = {.x = x, .y = y};
            
            if (keySize == 9 || keySize == 10) {
                [overworldChunks addObject:[NSValue value:&pos withObjCType:@encode(ChunkPos)]];
            } else {
                int32_t dimension = OSReadLittleInt32(keyData, 8);
                if (dimension == MCDimensionNether) {
                    [netherChunks addObject:[NSValue value:&pos withObjCType:@encode(ChunkPos)]];
                } else if (dimension == MCDimensionEnd) {
                    [endChunks addObject:[NSValue value:&pos withObjCType:@encode(ChunkPos)]];
                }
            }
        }
    }
    delete it;
    self->db->ReleaseSnapshot(readOptions.snapshot);
    
    [self willChangeValueForKey:@"overworldChunks"];
    _overworldChunks = overworldChunks.copy;
    [self didChangeValueForKey:@"overworldChunks"];
    [self willChangeValueForKey:@"netherChunks"];
    _netherChunks = netherChunks.copy;
    [self didChangeValueForKey:@"netherChunks"];
    [self willChangeValueForKey:@"endChunks"];
    _endChunks = endChunks.copy;
    [self didChangeValueForKey:@"endChunks"];
    [self.loadingWorldIndicator performSelectorOnMainThread:@selector(stopAnimation:) withObject:nil waitUntilDone:NO];

    [self willChangeValueForKey:@"players"];
    players = newPlayers;
    [self didChangeValueForKey:@"players"];
    
    // load external files
    NSString *thumbnailPath = [worldDirectory.path stringByAppendingPathComponent:@"world_icon.jpeg"];
    self.thumbnail = [[NSImage alloc] initWithContentsOfFile:thumbnailPath];
    self.worldName = [NSString stringWithContentsOfFile:[worldDirectory.path stringByAppendingPathComponent:@"levelname.txt"] encoding:NSUTF8StringEncoding error:nil];
    
    // level.dat
    std::ifstream fs([worldDirectory.path stringByAppendingPathComponent:@"level.dat"].fileSystemRepresentation);
    fs.seekg(8, fs.beg); // skip header
    nbt::io::stream_reader reader(fs, endian::little);
    const nbt::value compound(reader.read_compound().second);
    [self willChangeValueForKey:@"worldSeed"];
    levelDat = [self objectWithNBTValue:compound];
    [self didChangeValueForKey:@"worldSeed"];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tabView selectTabViewItemAtIndex:1];
    });
}

- (NSNumber*)worldSeed {
    // level.dat doesn't handle 64-bit numbers correctly
    uint64_t seed = [levelDat[@"RandomSeed"] unsignedLongLongValue];
    char buf[8];
    OSWriteLittleInt64(buf, 0, seed);
    return @(static_cast<int32_t>(OSReadLittleInt32(buf, 0)));
}

- (void)showPlayersWindow:(id)sender {
    for (NSWindowController *wc in self.windowControllers) {
        if ([wc isKindOfClass:[PlayersWindowController class]]) {
            [wc showWindow:self];
            return;
        }
    }
    PlayersWindowController *wc = [[PlayersWindowController alloc] initWithWindowNibName:@"PlayersWindowController"];
    [self addWindowController:wc];
    [wc showWindow:self];
}

- (NSArray<MCPlayer *> *)players {
    return players;
}

- (MCPlayer*)localPlayer {
    for (MCPlayer *player in players) {
        if (player.local) {
            return player;
        }
    }
    return nil;
}

- (void)switchLocalPlayerToUUID:(NSUUID *)newUUID withPlayer:(MCPlayer *)playerToBecomeLocal {
    MCPlayer *currentLocalPlayer = [self localPlayer];
    MCPlayer *newLocalPlayer = [currentLocalPlayer cloneWithUUID:newUUID];

    std::string playerUUIDToBecomeLocal = playerToBecomeLocal.uuid.UUIDString.lowercaseString.UTF8String;
    std::string newUUIDforLocalPlayer = newUUID.UUIDString.lowercaseString.UTF8String;
    
    ReadOptions readOptions;
    readOptions.decompress_allocator = new DecompressAllocator();
    readOptions.snapshot = db->GetSnapshot();
    
    Slice oldLocalPlayerData((const char*)currentLocalPlayer.data.bytes, (size_t)currentLocalPlayer.data.length);
    Slice newLocalPlayerData((const char*)playerToBecomeLocal.data.bytes, (size_t)playerToBecomeLocal.data.length);
    if (![self checkOk:db->Delete(leveldb::WriteOptions(), playerToBecomeLocal.key.UTF8String)]) return;
    if (![self checkOk:db->Put(leveldb::WriteOptions(), currentLocalPlayer.key.UTF8String, newLocalPlayerData)]) return;
    if (![self checkOk:db->Put(leveldb::WriteOptions(), newLocalPlayer.key.UTF8String, oldLocalPlayerData)]) return;
    db->ReleaseSnapshot(readOptions.snapshot);
    delete readOptions.decompress_allocator;
    [self updateChangeCount:NSChangeDone];
    
    // update player list
    NSMutableArray *newPlayers = self.players.mutableCopy;
    [newPlayers replaceObjectAtIndex:[newPlayers indexOfObject:playerToBecomeLocal] withObject:[playerToBecomeLocal cloneWithUUID:nil]];
    [newPlayers replaceObjectAtIndex:[newPlayers indexOfObject:currentLocalPlayer] withObject:newLocalPlayer];
    
    [self willChangeValueForKey:@"players"];
    players = newPlayers;
    [self didChangeValueForKey:@"players"];
}

- (id)objectWithNBTValue:(const nbt::value &)value {
    switch (value.get_type()) {
        case nbt::tag_type::Byte:
            return @(static_cast<const nbt::tag_byte&>(value.get()).get());
        case nbt::tag_type::Short:
            return @(static_cast<const nbt::tag_short&>(value.get()).get());
        case nbt::tag_type::Int:
            return @(static_cast<const nbt::tag_int&>(value.get()).get());
        case nbt::tag_type::Long:
            return @(static_cast<const nbt::tag_long&>(value.get()).get());
        case nbt::tag_type::Float:
            return @(static_cast<const nbt::tag_float&>(value.get()).get());
        case nbt::tag_type::Double:
            return @(static_cast<const nbt::tag_double&>(value.get()).get());
        case nbt::tag_type::Byte_Array: {
            const auto values = static_cast<const nbt::tag_byte_array&>(value.get());
            if (values.size() == 0) return [NSData data];
            signed char bytes[values.size()];
            for (size_t i = 0; i < values.size(); i++) {
                bytes[i] = values.at(i);
            }
            return [NSData dataWithBytes:bytes length:values.size()];
        } break;
        case nbt::tag_type::String:
            return @(static_cast<const nbt::tag_string&>(value.get()).get().c_str());
        case nbt::tag_type::List: {
            const auto values = static_cast<const nbt::tag_list&>(value.get());
            if (values.size() == 0) return @[];
            NSMutableArray *array = [NSMutableArray arrayWithCapacity:values.size()];
            for (size_t i = 0; i < values.size(); i++) {
                [array addObject:[self objectWithNBTValue:values.at(i)]];
            }
            return array.copy;
        } break;
        case nbt::tag_type::Compound: {
            const auto root = static_cast<const nbt::tag_compound&>(value.get());
            if (root.size() == 0) return @{};
            NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:root.size()];
            for(const auto& kv: root)
            {
                NSString *key = @(kv.first.c_str());
                if (kv.second) {
                    const auto &value = kv.second;
                    dict[key] = [self objectWithNBTValue:value];
                } else {
                    dict[key] = [NSNull null];
                }
            }
            return dict.copy;
        } break;
        case nbt::tag_type::Int_Array: {
            const auto values = static_cast<const nbt::tag_int_array&>(value.get());
            NSMutableArray *intArray = [NSMutableArray arrayWithCapacity:values.size()];
            for (size_t i = 0; i < values.size(); i++) {
                [intArray addObject:@(values.at(i))];
            }
            return intArray.copy;
        } break;
        default:
            return [NSNull null];
    }
}

@end
