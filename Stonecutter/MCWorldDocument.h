//
//  Document.h
//  Stonecutter
//
//  Created by Jesús A. Álvarez on 15/02/2018.
//  Copyright © 2018 namedfork. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MCTypes.h"

@class ProgressWindow, MCPlayer;

@interface MCWorldDocument : NSDocument

@property (nonatomic, weak) IBOutlet ProgressWindow *progressWindow;
@property (nonatomic, weak) IBOutlet NSTabView *tabView;

@property (nonatomic, weak) IBOutlet NSProgressIndicator *loadingWorldIndicator;

@property (nonatomic, readonly) NSArray<MCPlayer*> *players;
@property (nonatomic, readonly) MCPlayer *localPlayer;
@property (nonatomic, strong) NSImage *thumbnail;
@property (nonatomic, strong) NSString *worldName;
@property (nonatomic, readonly) NSNumber *worldSeed;
@property (nonatomic, readonly) NSSet<NSValue*> *overworldChunks, *netherChunks, *endChunks;

- (void)switchLocalPlayerToUUID:(NSUUID*)newUUID withPlayer:(MCPlayer*)playerToBecomeLocal;
- (IBAction)showPlayersWindow:(id)sender;
- (NSSet<NSValue*>*)chunksForDimension:(MCDimension)dim;

@end

