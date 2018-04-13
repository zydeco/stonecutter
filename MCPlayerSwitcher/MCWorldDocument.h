//
//  Document.h
//  MCPlayerSwitcher
//
//  Created by Jesús A. Álvarez on 15/02/2018.
//  Copyright © 2018 namedfork. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class ProgressWindow, MCPlayer;

@interface MCWorldDocument : NSDocument

@property (nonatomic, weak) IBOutlet ProgressWindow *progressWindow;
@property (nonatomic, weak) IBOutlet NSTabView *tabView;

@property (nonatomic, weak) IBOutlet NSProgressIndicator *loadingPlayersIndicator;

@property (nonatomic, readonly) NSArray<MCPlayer*> *players;
@property (nonatomic, weak) IBOutlet NSTableView *playersTableView;
@property (nonatomic, weak) IBOutlet NSTextField *localPlayerNewUUIDField;

- (IBAction)showServer:(id)sender;

@end

