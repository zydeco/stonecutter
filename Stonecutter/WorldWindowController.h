//
//  WorldWindowController.h
//  Stonecutter
//
//  Created by Jesús A. Álvarez on 20/05/2018.
//  Copyright © 2018 namedfork. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MCTypes.h"
#import "WorldView.h"

@class MCWorldDocument;

@interface WorldWindowController : NSWindowController

@property (assign) MCWorldDocument *document;
@property (assign) MCDimension dimension;

@property (nonatomic, weak) IBOutlet NSScrollView *scrollView;
@property (nonatomic, weak) IBOutlet WorldView *worldView;

@end
