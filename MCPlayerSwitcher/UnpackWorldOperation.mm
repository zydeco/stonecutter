//
//  UnpackWorldOperation.m
//  MCPlayerSwitcher
//
//  Created by Jesús A. Álvarez on 03/03/2018.
//  Copyright © 2018 namedfork. All rights reserved.
//

#import "UnpackWorldOperation.h"

#include "libzippp.h"
#include <iostream>
#include <fstream>

using namespace libzippp;

@implementation UnpackWorldOperation

- (NSString *)localizedName {
    return @"Unpacking world…";
}

- (void)main {
    ssize_t totalSize = 0;
    ZipArchive zf(self.source.fileSystemRepresentation);
    zf.open(ZipArchive::READ_ONLY);
    for (libzippp_int64 i = 0; i < zf.getNbEntries(); i++) {
        ZipEntry entry = zf.getEntry(i);
        totalSize += entry.getSize();
    }
    
    self.progress.totalUnitCount = totalSize;
    NSFileManager *fm = [NSFileManager defaultManager];
    NSDictionary *fsAttributes = [fm attributesOfFileSystemForPath:self.destination.path error:NULL];
    if ([fsAttributes[NSFileSystemFreeSize] longLongValue] < totalSize * 1.1) {
        // not enough free space
        NSLog(@"not enough space");
        self.error = [NSError errorWithDomain:NSPOSIXErrorDomain code:ENOSPC userInfo:nil];
        zf.close();
        return;
    }
    
    NSString *basePath = self.destination.path;
    for (libzippp_int64 i = 0; i < zf.getNbEntries(); i++) {
        ZipEntry entry = zf.getEntry(i);
        if (entry.isDirectory()) continue;
        
        // am I cancelled?
        if (self.cancelled) {
            self.error = [NSError errorWithDomain:NSPOSIXErrorDomain code:ECANCELED userInfo:nil];
            break;
        }
        
        // find extraction path
        NSString *extractPath = [basePath stringByAppendingPathComponent:@(entry.getName().c_str())].stringByStandardizingPath;
        if (![extractPath hasPrefix:basePath]) {
            NSLog(@"Invalid extraction path %@", extractPath);
            continue;
        }
        
        // check extraction directory
        NSString *extractDirectory = [extractPath stringByDeletingLastPathComponent];
        BOOL isDirectory;
        if (![fm fileExistsAtPath:extractDirectory isDirectory:&isDirectory]) {
            // create directory
            NSError *error = nil;
            [fm createDirectoryAtPath:extractDirectory withIntermediateDirectories:YES attributes:nil error:&error];
            if (error) {
                self.error = error;
                break;
            }
        } else if (!isDirectory) {
            // exists as file
            NSLog(@"this should never happen");
            self.error = [NSError errorWithDomain:NSPOSIXErrorDomain code:EEXIST userInfo:nil];
            break;
        }
        
        // extract file
        std::ofstream extractStream;
        extractStream.open(extractPath.fileSystemRepresentation);
        entry.readContent(extractStream);
        extractStream.close();
        self.progress.completedUnitCount += entry.getSize();
    }
    
    zf.close();
}

@end
