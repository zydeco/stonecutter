//
//  Document.h
//  Stonecutter
//
//  Created by Jesús A. Álvarez on 15/02/2018.
//  Copyright © 2018 namedfork. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MCTypes.h"
#import "PlayersWindowController.h"

@class ProgressWindow, MCPlayer;

@interface MCWorldDocument : NSDocument

@property (nonatomic, weak) IBOutlet ProgressWindow *progressWindow;
@property (nonatomic, weak) IBOutlet NSTabView *tabView;

@property (nonatomic, weak) IBOutlet NSProgressIndicator *loadingWorldIndicator;

@property (nonatomic, readonly) NSArray<MCPlayer*> *players;
@property (nonatomic, readonly) MCPlayer *localPlayer;

- (void)switchLocalPlayerToUUID:(NSUUID*)newUUID withPlayer:(MCPlayer*)playerToBecomeLocal;
@end
