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
#import "PerformActionOperation.h"
#import "MCPlayer.h"
#import "DocumentController.h"

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
    PerformActionOperation *listPlayersOperation;
    DB *db;
    NSArray<MCPlayer*> *players;
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
                [self openWorld];
            }
        }];
        [operation addObserver:self forKeyPath:@"finished" options:0 context:NULL];
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
    if (worldDirectory != nil) {
        if (listPlayersOperation.isExecuting) {
            [listPlayersOperation cancel];
            [listPlayersOperation waitUntilFinished];
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
    [self performSelector:@selector(showProgressForWorldOperation:) withObject:unpackOperation afterDelay:0.0];
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
    if (listPlayersOperation.isExecuting) {
        [listPlayersOperation cancel];
        [listPlayersOperation waitUntilFinished];
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
    
    [self.loadingPlayersIndicator startAnimation:nil];
    NSURL *dbDirectory = [worldDirectory URLByAppendingPathComponent:@"db"];
    if ([self checkOk: DB::Open(options, dbDirectory.fileSystemRepresentation, &db)]) {
        [self listPlayers];
    }
}

#pragma mark - Player List

- (void)listPlayers {
    [self.loadingPlayersIndicator startAnimation:nil];
    [self.tabView selectTabViewItemAtIndex:0];
    
    listPlayersOperation = [PerformActionOperation operationWithTarget:self action:@selector(listPlayers:)];
    [listPlayersOperation performSelectorInBackground:@selector(start) withObject:nil];
}

- (void)listPlayers:(NSOperation*)operation {
    ReadOptions readOptions;
    readOptions.decompress_allocator = new DecompressAllocator();
    readOptions.snapshot = self->db->GetSnapshot();
    Iterator *it = self->db->NewIterator(readOptions);
    NSMutableArray<MCPlayer*> *newPlayers = [NSMutableArray arrayWithCapacity:4];
    for (it->SeekToFirst(); it->Valid(); it->Next()) {
        if (operation.cancelled) {
            break;
        }
        BOOL isLocalPlayer = it->key().size() == 13 && memcmp(it->key().data(), "~local_player", 13) == 0;
        BOOL isOtherPlayer = it->key().size() == 43 && strncmp(it->key().data(), "player_", 7) == 0;
        if (isLocalPlayer || isOtherPlayer) {
            NSString *playerKey = @(it->key().ToString().c_str());
            NSData *playerData = [NSData dataWithBytes:it->value().data() length:it->value().size()];
            [newPlayers addObject:[[MCPlayer alloc] initWithKey:playerKey data:playerData]];
        }
    }
    delete it;
    self->db->ReleaseSnapshot(readOptions.snapshot);
    
    [self performSelectorOnMainThread:@selector(showPlayers:) withObject:newPlayers waitUntilDone:NO];
}

- (void)showPlayers:(NSArray<MCPlayer*>*)newPlayers {
    [self.loadingPlayersIndicator stopAnimation:nil];
    [self willChangeValueForKey:@"players"];
    players = newPlayers;
    [self didChangeValueForKey:@"players"];
    [self.tabView selectTabViewItemAtIndex:1];
    [self validateInput];
}

- (NSArray<MCPlayer *> *)players {
    return players;
}

#pragma mark - Change UUID

- (void)controlTextDidChange:(NSNotification *)notification {
    if (notification.object == self.localPlayerNewUUIDField) {
        [self validateInput];
    }
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
    if (notification.object == self.playersTableView) {
        [self validateInput];
    }
}

- (MCPlayer*)selectedPlayer {
    NSInteger row = self.playersTableView.selectedRow;
    if (row == -1) {
        return nil;
    } else {
        return players[row];
    }
}

- (MCPlayer*)localPlayer {
    for (MCPlayer *player in players) {
        if (player.local) {
            return player;
        }
    }
    return nil;
}

- (NSUUID*)inputUUID {
    NSString *uuidString = [self.localPlayerNewUUIDField.stringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    return [[NSUUID alloc] initWithUUIDString:uuidString];
}

- (void)validateInput {
    NSUUID *inputUUID = [self inputUUID];
    MCPlayer *selectedPlayer = [self selectedPlayer];
    if (selectedPlayer == nil || inputUUID == nil) {
        self.playersSaveButton.enabled = NO;
        return;
    }
    NSMutableArray* otherUUIDs = [[players valueForKeyPath:@"uuid"] mutableCopy];
    [otherUUIDs removeObject:[NSNull null]];
    [otherUUIDs removeObject:selectedPlayer.uuid];
    self.playersSaveButton.enabled = inputUUID && !selectedPlayer.local && ![otherUUIDs containsObject:inputUUID];
}

- (void)showServer:(id)sender {
    [[AppDelegate sharedInstance] showServer];
}

- (void)savePlayerChanges:(id)sender {
    MCPlayer *playerToBecomeLocal = [self selectedPlayer];
    MCPlayer *currentLocalPlayer = [self localPlayer];
    MCPlayer *newLocalPlayer = [currentLocalPlayer cloneWithUUID:[self inputUUID]];
    std::string playerUUIDToBecomeLocal = playerToBecomeLocal.uuid.UUIDString.lowercaseString.UTF8String;
    std::string newUUIDforLocalPlayer = [self inputUUID].UUIDString.lowercaseString.UTF8String;
    [self.playersTableView deselectAll:self];
    
    ReadOptions readOptions;
    readOptions.decompress_allocator = new DecompressAllocator();
    readOptions.snapshot = db->GetSnapshot();
    
    Slice oldLocalPlayerData((const char*)currentLocalPlayer.data.bytes, (size_t)currentLocalPlayer.data.length);
    Slice newLocalPlayerData((const char*)playerToBecomeLocal.data.bytes, (size_t)playerToBecomeLocal.data.length);
    if (![self checkOk:db->Delete(leveldb::WriteOptions(), playerToBecomeLocal.key.UTF8String)]) return;
    if (![self checkOk:db->Put(leveldb::WriteOptions(), currentLocalPlayer.key.UTF8String, newLocalPlayerData)]) return;
    if (![self checkOk:db->Put(leveldb::WriteOptions(), newLocalPlayer.key.UTF8String, oldLocalPlayerData)]) return;
    db->ReleaseSnapshot(readOptions.snapshot);
    [self updateChangeCount:NSChangeDone];
    
    // update player list
    NSMutableArray *newPlayers = self.players.mutableCopy;
    [newPlayers replaceObjectAtIndex:[newPlayers indexOfObject:playerToBecomeLocal] withObject:[playerToBecomeLocal cloneWithUUID:nil]];
    [newPlayers replaceObjectAtIndex:[newPlayers indexOfObject:currentLocalPlayer] withObject:newLocalPlayer];
    [self showPlayers:newPlayers];
}

# pragma mark - Copy UUID

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
    if (menuItem.action == @selector(copy:)) {
        return [self selectedPlayer] != nil;
    } else {
        return [super validateMenuItem:menuItem];
    }
}

- (void)copy:(id)sender {
    NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
    [pasteboard clearContents];
    [pasteboard setString:[self selectedPlayer].uuid.UUIDString forType:NSStringPboardType];
}

@end
