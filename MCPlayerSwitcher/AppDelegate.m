//
//  AppDelegate.m
//  MCPlayerSwitcher
//
//  Created by Jesús A. Álvarez on 15/02/2018.
//  Copyright © 2018 namedfork. All rights reserved.
//

#import "AppDelegate.h"
#import "DocumentController.h"
#import "MCServer.h"

@interface AppDelegate () <MCServerDelegate>

@end

@implementation AppDelegate
{
    DocumentController *documentController;
    MCServer *server;
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
    server = [MCServer new];
    server.delegate = self;
    [server performSelectorInBackground:@selector(run) withObject:nil];
}

- (void)mcServer:(MCServer *)server didLogInUser:(NSUUID *)uuid withDisplayName:(NSString *)displayName {
    NSLog(@"Login from %@: %@", uuid, displayName);
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
    [server performSelector:@selector(stop)];
}

- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender {
    return NO;
}

- (BOOL)applicationOpenUntitledFile:(NSApplication *)sender {
    return NO;
}

@end
