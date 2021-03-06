//
//  PlayersWindowController.h
//  Stonecutter
//
//  Created by Jesús A. Álvarez on 17/05/2018.
//  Copyright © 2018 namedfork. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class MCWorldDocument;

@interface PlayersWindowController : NSWindowController

@property (assign) MCWorldDocument *document;

@property (nonatomic, weak) IBOutlet NSTableView *playersTableView;
@property (nonatomic, weak) IBOutlet NSTextField *localPlayerNewUUIDField;
@property (nonatomic, weak) IBOutlet NSButton *playersSaveButton;

- (IBAction)showServer:(id)sender;
- (IBAction)savePlayerChanges:(id)sender;

@end
