//
//  DocumentController.m
//  MCPlayerSwitcher
//
//  Created by Jesús A. Álvarez on 15/02/2018.
//  Copyright © 2018 namedfork. All rights reserved.
//

#import "DocumentController.h"

@implementation DocumentController

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
