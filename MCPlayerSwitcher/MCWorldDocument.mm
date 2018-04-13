//
//  Document.m
//  MCPlayerSwitcher
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

#import "AppDelegate.h"
#import "ProgressWindow.h"
#import "UnpackWorldOperation.h"
#import "PackWorldOperation.h"
#import "MCPlayer.h"

using namespace libzippp;
using namespace leveldb;

NSErrorDomain LevelDBErrorDomain = @"LevelDBErrorDomain";

@interface MCWorldDocument () <NSTableViewDelegate>

@end

@implementation MCWorldDocument
{
    NSURL *worldDirectory;
    UnpackWorldOperation *unpackOperation;
    PackWorldOperation *packOperation;
    DB *db;
    NSArray<MCPlayer*> *players;
}

- (instancetype)init {
    self = [super init];
    if (self) {
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
    [self performSelector:@selector(showProgressForWorldOperation:) withObject:unpackOperation afterDelay:0.0];
    [self.tabView selectFirstTabViewItem:nil];
}

#pragma mark - Progress UI

- (void)showProgressForWorldOperation:(WorldOperation*)operation {
    if (!operation.isFinished) {
        _progressWindow.progress = operation.progress;
        _progressWindow.progresLabel.stringValue = operation.localizedName;
        [self.windowForSheet beginSheet:_progressWindow completionHandler:^(NSModalResponse returnCode) {
            if (operation.error) {
                [self giveUpWithError:operation.error];
            } else if (operation == unpackOperation) {
                [self.loadingPlayersIndicator startAnimation:nil];
                [self openWorld];
            }
        }];
        [operation addObserver:self forKeyPath:@"finished" options:0 context:NULL];
    } else if (operation.error) {
        [self giveUpWithError:operation.error];
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
        [self.windowForSheet endSheet:_progressWindow returnCode:response];
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
    worldDirectory = [fileManager URLForDirectory:NSItemReplacementDirectory inDomain:NSUserDomainMask appropriateForURL:url create:YES error:outError];
    if (worldDirectory == nil) {
        return NO;
    }
    NSLog(@"opening into %@", worldDirectory);
    
    // extract zip in background
    unpackOperation = [UnpackWorldOperation new];
    unpackOperation.source = url;
    unpackOperation.destination = worldDirectory;
    [unpackOperation performSelectorInBackground:@selector(start) withObject:nil];
    
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

- (void)dealloc {
    [self cleanupTemporaryFiles];
    if (db) {
        delete db;
    }
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
    
    NSURL *dbDirectory = [worldDirectory URLByAppendingPathComponent:@"db"];
    if ([self checkOk: DB::Open(options, dbDirectory.fileSystemRepresentation, &db)]) {
        [self performSelectorInBackground:@selector(listPlayers) withObject:nil];
    }
}

#pragma mark - Player List

- (void)listPlayers {
    ReadOptions readOptions;
    readOptions.decompress_allocator = new DecompressAllocator();
    // iterate through everything
    readOptions.snapshot = db->GetSnapshot();
    Iterator *it = db->NewIterator(readOptions);
    NSMutableArray<MCPlayer*> *newPlayers = [NSMutableArray arrayWithCapacity:4];
    for (it->SeekToFirst(); it->Valid(); it->Next()) {
        BOOL isLocalPlayer = it->key().size() == 13 && memcmp(it->key().data(), "~local_player", 13) == 0;
        BOOL isOtherPlayer = it->key().size() == 43 && strncmp(it->key().data(), "player_", 7) == 0;
        if (isLocalPlayer || isOtherPlayer) {
            NSString *playerKey = @(it->key().ToString().c_str());
            NSData *playerData = [NSData dataWithBytes:it->value().data() length:it->value().size()];
            [newPlayers addObject:[[MCPlayer alloc] initWithKey:playerKey data:playerData]];
        }
    }
    delete it;
    db->ReleaseSnapshot(readOptions.snapshot);
    
    [self performSelectorOnMainThread:@selector(showPlayers:) withObject:newPlayers waitUntilDone:NO];
}

- (void)showPlayers:(NSArray<MCPlayer*>*)newPlayers {
    [self.loadingPlayersIndicator stopAnimation:nil];
    [self willChangeValueForKey:@"players"];
    players = newPlayers;
    [self didChangeValueForKey:@"players"];
    [self.tabView selectTabViewItemAtIndex:1];
}

- (NSArray<MCPlayer *> *)players {
    return players;
}

- (void)showServer:(id)sender {
    [[AppDelegate sharedInstance] showServer];
}

@end
