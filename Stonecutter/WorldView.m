//
//  WorldView.m
//  Stonecutter
//
//  Created by Jesús A. Álvarez on 20/05/2018.
//  Copyright © 2018 namedfork. All rights reserved.
//

#import "WorldView.h"
#import "MCTypes.h"

@implementation WorldView
{
    ChunkPos posMin, posMax, posOffset;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    
}

- (void)setChunks:(NSSet<NSValue *> *)chunks {
    _chunks = chunks;
    [self calculateMapSize];
}

- (void)calculateMapSize {
    [_chunks.anyObject getValue:&posMin];
    posMax = posMin;
    for (NSValue *chunk in _chunks) {
        ChunkPos pos;
        [chunk getValue:&pos];
        if (pos.x < posMin.x) posMin.x = pos.x;
        if (pos.x > posMax.x) posMax.x = pos.x;
        if (pos.z < posMin.z) posMin.z = pos.z;
        if (pos.z > posMax.z) posMax.z = pos.z;
    }
    
    posMin.x -= 4;
    posMin.z -= 4;
    posMax.x += 4;
    posMax.z += 4;
    [self performSelectorOnMainThread:@selector(updateMapSize) withObject:nil waitUntilDone:NO];
}

- (void)updateMapSize {
    CGFloat chunksWide = posMax.x - posMin.x + 1;
    CGFloat chunksHigh = posMax.z - posMin.z + 1;
    self.frame = NSMakeRect(0, 0, _chunkSize * chunksWide, _chunkSize * chunksHigh);
    //NSLog(@"map size: %@", NSStringFromRect(self.frame));
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];

    [[NSColor grayColor] setFill];
    for (NSValue *chunk in _chunks) {
        ChunkPos pos;
        [chunk getValue:&pos];
        NSRect chunkRect = NSMakeRect((-posMin.x + pos.x) * _chunkSize, (posMax.z - pos.z) * _chunkSize, _chunkSize, _chunkSize);
        if (NSIntersectsRect(dirtyRect, chunkRect)) {
            NSRectFill(chunkRect);
        }
    }
}

@end
