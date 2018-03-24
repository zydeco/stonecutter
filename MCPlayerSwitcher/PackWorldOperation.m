//
//  PackWorldOperation.m
//  MCPlayerSwitcher
//
//  Created by Jesús A. Álvarez on 23/03/2018.
//  Copyright © 2018 namedfork. All rights reserved.
//

#import "PackWorldOperation.h"
#import "RSWeakifySelf.h"

#include <zip.h>

NSErrorDomain LibZipErrorDomain = @"LibZipErrorDomain";

#define kZipProgressGranularity 10000

void updateZipProgress(zip_t * zip, double progress, void *ud) {
    PackWorldOperation *op = (__bridge PackWorldOperation*)ud;
    op.progress.completedUnitCount = progress * kZipProgressGranularity;
}

@implementation PackWorldOperation

- (NSString *)localizedName {
    return @"Saving world…";
}

- (ssize_t)calculateTotalSize {
    __block ssize_t totalSize = 0;
    [self enumerateWorldFiles:^(NSURL *fileURL, size_t fileSize) {
        totalSize += fileSize;
    }];
    return totalSize;
}

- (NSDirectoryEnumerator<NSURL*>*)_directoryEnumerator {
    return [[NSFileManager defaultManager] enumeratorAtURL:self.source includingPropertiesForKeys:@[NSURLNameKey, NSURLIsDirectoryKey, NSURLTotalFileSizeKey] options:0 errorHandler:^BOOL(NSURL * _Nonnull url, NSError * _Nonnull error) {
        self.error = error;
        [self cancel];
        return NO;
    }];
}

- (void)enumerateWorldFiles:(void(^)(NSURL *fileURL, size_t fileSize))block {
    NSError *error = nil;
    for (NSURL *fileURL in [self _directoryEnumerator]) {
        // am I cancelled?
        if (self.cancelled) {
            if (self.error == nil) {
                self.error = [NSError errorWithDomain:NSPOSIXErrorDomain code:ECANCELED userInfo:nil];
            }
            return;
        }
        
        // skip directories
        NSNumber *isDirectory;
        if (![fileURL getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:&error]) {
            self.error = error;
            return;
        }
        if (isDirectory.boolValue) continue;
        
        // get size
        NSNumber *fileSize;
        if (![fileURL getResourceValue:&fileSize forKey:NSURLTotalFileSizeKey error:&error]) {
            self.error = error;
            return;
        }
        
        block(fileURL, fileSize.unsignedLongLongValue);
    }
}

- (NSError*)errorWithZipErrorCode:(int)zipError {
    zip_error_t ze;
    zip_error_init_with_code(&ze, zipError);
    NSError *error = [self errorWithZipError:&ze];
    zip_error_fini(&ze);
    return error;
}

- (NSError*)errorWithZipError:(zip_error_t*)ze {
    if (ze == NULL) {
        return nil;
    }
    NSMutableDictionary *userInfo = @{NSLocalizedFailureReasonErrorKey: @(zip_error_strerror(ze))}.mutableCopy;
    if (zip_error_system_type(ze) == ZIP_ET_SYS) {
        userInfo[NSUnderlyingErrorKey] = [NSError errorWithDomain:NSPOSIXErrorDomain code:zip_error_code_system(ze) userInfo:nil];
    }
    return [NSError errorWithDomain:LibZipErrorDomain code:zip_error_code_zip(ze) userInfo:userInfo];
}

- (void)main {
    self.progress.totalUnitCount = kZipProgressGranularity;
    if (self.error) return;
    
    int zipError;
    zip_t *zip = zip_open(self.destination.fileSystemRepresentation, ZIP_CREATE | ZIP_TRUNCATE, &zipError);
    if (zip == NULL) {
        self.error = [self errorWithZipErrorCode:zipError];
        return;
    }
    
    NSString *basePath = self.source.path.stringByStandardizingPath;
    [self enumerateWorldFiles:^void(NSURL *fileURL, size_t fileSize) {
        // add file to zip
        NSString *filePath = fileURL.path.stringByStandardizingPath;
        if ([filePath hasPrefix:basePath]) {
            NSString *entryName = [filePath substringFromIndex:basePath.length + 1];
            NSLog(@"adding %@", entryName);
            
            struct zip_source *source = zip_source_file(zip, filePath.fileSystemRepresentation, 0, -1);
            if (source == NULL) {
                self.error = [self errorWithZipError:zip_get_error(zip)];
                [self cancel];
                return;
            } if (zip_file_add(zip, entryName.fileSystemRepresentation, source, ZIP_FL_ENC_UTF_8 | ZIP_FL_OVERWRITE) >= 0){
                // added file
            } else {
                self.error = [self errorWithZipError:zip_get_error(zip)];
                [self cancel];
                zip_source_free(source);
                return;
            }
        } else {
            NSLog(@"Invalid save path!");
            self.error = [NSError errorWithDomain:NSPOSIXErrorDomain code:ENOENT userInfo:nil];
            [self cancel];
        }
    }];
    
    self.progress.cancellable = NO;
    zip_register_progress_callback_with_state(zip, 1.0 / kZipProgressGranularity, updateZipProgress, NULL, (__bridge void*)self);
    zip_close(zip);
    self.progress.completedUnitCount = self.progress.totalUnitCount;
}

@end
