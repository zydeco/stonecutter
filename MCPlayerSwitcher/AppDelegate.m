//
//  AppDelegate.m
//  MCPlayerSwitcher
//
//  Created by Jesús A. Álvarez on 15/02/2018.
//  Copyright © 2018 namedfork. All rights reserved.
//

#import "AppDelegate.h"
#import "DocumentController.h"

@interface AppDelegate ()

@end

@implementation AppDelegate
{
    DocumentController *documentController;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        // override NSDocumentController
        documentController = [[DocumentController alloc] init];
    }
    return self;
}

+ (instancetype)sharedInstance {
    return NSApp.delegate;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {

}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender {
    return NO;
}

- (BOOL)applicationOpenUntitledFile:(NSApplication *)sender {
    return NO;
}

@end
