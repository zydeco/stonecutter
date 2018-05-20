//
//  WorldView.h
//  Stonecutter
//
//  Created by Jesús A. Álvarez on 20/05/2018.
//  Copyright © 2018 namedfork. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface WorldView : NSView

@property (nonatomic, assign) CGFloat chunkSize;
@property (nonatomic, retain) NSSet<NSValue*> *chunks;

@end
