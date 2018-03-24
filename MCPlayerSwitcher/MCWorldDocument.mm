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

using namespace libzippp;

@interface MCWorldDocument ()

@end

@implementation MCWorldDocument
{
    NSURL *worldDirectory;
    UnpackWorldOperation *unpackOperation;
    PackWorldOperation *packOperation;
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
}

#pragma mark - Progress UI

- (void)showProgressForWorldOperation:(WorldOperation*)operation {
    if (!operation.isFinished) {
        _progressWindow.progress = operation.progress;
        _progressWindow.progresLabel.stringValue = operation.localizedName;
        [self.windowForSheet beginSheet:_progressWindow completionHandler:^(NSModalResponse returnCode) {
            if (operation.error) {
                [self giveUpWithError:operation.error];
            }
        }];
        [operation addObserver:self forKeyPath:@"finished" options:0 context:NULL];
    } else if (operation.error) {
        [self giveUpWithError:operation.error];
    }
}

- (void)giveUpWithError:(NSError*)error {
    NSAlert *alert = [NSAlert alertWithError:error];
    alert.alertStyle = NSAlertStyleWarning;
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
    
    NSLog(@"%@", NSStringFromSelector(_cmd));
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
}

- (void)cleanupTemporaryFiles {
    if (worldDirectory) {
        [[NSFileManager defaultManager] removeItemAtURL:worldDirectory error:NULL];
    }
}

@end
