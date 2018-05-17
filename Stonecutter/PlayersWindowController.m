//
//  PlayersWindowController.m
//  Stonecutter
//
//  Created by Jesús A. Álvarez on 17/05/2018.
//  Copyright © 2018 namedfork. All rights reserved.
//

#import "PlayersWindowController.h"
#import "AppDelegate.h"
#import "MCWorldDocument.h"
#import "MCPlayer.h"

@interface PlayersWindowController ()

@end

@implementation PlayersWindowController

@dynamic document;

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

- (void)showServer:(id)sender {
    [[AppDelegate sharedInstance] showServer];
}

- (NSString *)windowTitleForDocumentDisplayName:(NSString *)displayName {
    return [displayName stringByAppendingString:@" – Players"];
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
        return self.document.players[row];
    }
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
    NSMutableArray* otherUUIDs = [[self.document.players valueForKeyPath:@"uuid"] mutableCopy];
    [otherUUIDs removeObject:[NSNull null]];
    [otherUUIDs removeObject:selectedPlayer.uuid];
    self.playersSaveButton.enabled = inputUUID && !selectedPlayer.local && ![otherUUIDs containsObject:inputUUID];
}

- (void)savePlayerChanges:(id)sender {
    MCPlayer *playerToBecomeLocal = [self selectedPlayer];
    //    [self.playersTableView deselectAll:self];
    [self.document switchLocalPlayerToUUID:[self inputUUID] withPlayer:playerToBecomeLocal];
}

#pragma mark - Copy UUID

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
