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

@interface AppDelegate () <MCServerDelegate, NSWindowDelegate>

@end

@implementation AppDelegate
{
    MCServer *server;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        // override NSDocumentController
        _documentController = [[DocumentController alloc] init];
        // what if several instances are running?
        [_documentController cleanupTemporaryFiles];
    }
    return self;
}

+ (instancetype)sharedInstance {
    return (AppDelegate*)NSApp.delegate;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {

}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
    [server stop];
}

- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender {
    return NO;
}

- (BOOL)applicationOpenUntitledFile:(NSApplication *)sender {
    return NO;
}

- (void)logServerMessage:(NSString*)message {
    if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:_cmd withObject:message waitUntilDone:NO];
        return;
    }
    NSMutableAttributedString *attributedMessage = [[NSMutableAttributedString alloc] initWithString:message];
    NSFont *font = [NSFont fontWithName:@"Courier New" size:12.0];
    [attributedMessage addAttribute:NSFontAttributeName value:font range:NSMakeRange(0, attributedMessage.length)];
    [self.serverLogView.textStorage appendAttributedString:attributedMessage];
    [self.serverLogView.textStorage appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n"]];
}

- (void)mcServerDidStart:(MCServer *)server {
    [self logServerMessage:[NSString stringWithFormat:@"Starting server “%@”", server.name]];
    [self logServerMessage:@"Connect to find your UUID"];
}

- (void)mcServer:(MCServer *)server didLogInUser:(NSUUID *)uuid withDisplayName:(NSString *)displayName {
    [self logServerMessage:[NSString stringWithFormat:@"Login from %@: %@", uuid, displayName]];
}

- (void)mcServerDidStop:(MCServer *)server {
    [self logServerMessage:@"Server shut down"];
}

- (void)showServer {
    [self.serverWindow makeKeyAndOrderFront:self];
    if (server == nil) {
        server = [MCServer new];
        server.delegate = self;
        [server performSelectorInBackground:@selector(run) withObject:nil];
    }
}

- (void)windowWillClose:(NSNotification *)notification {
    if (notification.object == self.serverWindow) {
        [server stop];
    }
}

@end
