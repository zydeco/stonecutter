//
//  DocumentController.m
//  MCPlayerSwitcher
//
//  Created by Jesús A. Álvarez on 15/02/2018.
//  Copyright © 2018 namedfork. All rights reserved.
//

#import "DocumentController.h"

@implementation DocumentController
{
    NSURL *worldDirectory;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        worldDirectory = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:@"Worlds"]];
    }
    return self;
}

- (NSURL *)urlForUnpackingWorld:(NSURL*)worldURL {
    NSString *path = [worldDirectory.path stringByAppendingPathComponent:worldURL.lastPathComponent];
    NSString *name = worldURL.lastPathComponent.stringByDeletingPathExtension;
    NSString *extension = worldURL.lastPathComponent.pathExtension;
    int try = 1;
    while ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        NSString *alternateName;
        if (extension.length == 0) {
            alternateName = [NSString stringWithFormat:@"%@ %d", name, try++];
        } else {
            alternateName = [NSString stringWithFormat:@"%@ %d.%@", name, try++, extension];
        }
        path = [worldDirectory.path stringByAppendingPathComponent:alternateName];
    }
    return [NSURL fileURLWithPath:path];
}

- (void)cleanupTemporaryFiles {
    [[NSFileManager defaultManager] removeItemAtURL:worldDirectory error:nil];
}

- (void)newDocument:(id)sender {
    
}

- (NSDocument *)makeUntitledDocumentOfType:(NSString *)typeName error:(NSError * _Nullable __autoreleasing *)outError {
    return nil;
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
    if (menuItem.action == @selector(newDocument:)) {
        return NO;
    }
    return [super validateMenuItem:menuItem];
}

@end
