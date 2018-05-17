//
//  HotbarPreviewRenderer.m
//  Stonecutter
//
//  Created by Jesús A. Álvarez on 24/03/2018.
//  Copyright © 2018 namedfork. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "HotbarPreviewRenderer.h"

@implementation HotbarPreviewRenderer

+ (BOOL)allowsReverseTransformation {
    return NO;
}

+ (Class)transformedValueClass {
    return [NSImage class];
}

- (id)transformedValue:(id)value {
    if ([value isKindOfClass:[NSArray class]] && [value count] == 9) {
        return [self imageWithHotbarItems:value];
    } else {
        return nil;
    }
}

- (NSImage*)imageWithHotbarItems:(NSArray<NSNumber*>*)hotbarItems {
    CGFloat itemSize = 19.0;
    CGFloat itemSeparation = 2.0;
    CGSize baseSize = CGSizeMake(itemSize * hotbarItems.count + itemSeparation * (hotbarItems.count-1), itemSize);
    CGSize dstSize = baseSize;
    CGFloat dstOffset = itemSize + itemSeparation;
    NSRect dstRect = NSMakeRect(0, 0, itemSize, itemSize);
    if ([NSScreen mainScreen].backingScaleFactor > 1.0) {
        dstSize.width *= 2.0;
        dstSize.height *= 2.0;
        dstOffset *= 2.0;
        dstRect.size.width *= 2.0;
        dstRect.size.height *= 2.0;
    }
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef ctx = CGBitmapContextCreate(NULL, dstSize.width, dstSize.height, 8, 0, colorSpace, kCGImageAlphaPremultipliedLast + kCGBitmapByteOrder32Host);
    CGColorSpaceRelease(colorSpace);
    [NSGraphicsContext saveGraphicsState];
    [NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithCGContext:ctx flipped:YES]];
    
    NSImage *blockSheet = [NSImage imageNamed:@"blocks"];
    NSImage *itemSheet = [NSImage imageNamed:@"items"];
    for (int i=0; i < hotbarItems.count; i++) {
        NSInteger itemID = hotbarItems[i].integerValue;
        BOOL enchanted = NO;
        if (itemID < 0) {
            enchanted = YES;
            itemID *= -1;
        }
        
        if (itemID >= 256) {
            // item
            [itemSheet drawInRect:dstRect fromRect:NSMakeRect(0, (itemID - 256) * 16, 16, 16) operation:NSCompositingOperationCopy fraction:1.0];
        } else if (itemID > 0) {
            // block
            [blockSheet drawInRect:dstRect fromRect:NSMakeRect(0, 4807 - (itemID * 19), 19, 19) operation:NSCompositingOperationCopy fraction:1.0];
        }
        if (enchanted) {
            [[[NSColor purpleColor] colorWithAlphaComponent:0.5] setFill];
            NSRectFillUsingOperation(dstRect, NSCompositingOperationSourceAtop);
        }
        dstRect.origin.x += dstOffset;
    }
    [NSGraphicsContext restoreGraphicsState];
    
    CGImageRef imageRef = CGBitmapContextCreateImage(ctx);
    NSImage *image = [[NSImage alloc] initWithCGImage:imageRef size:NSSizeFromCGSize(baseSize)];
    
    CGImageRelease(imageRef);
    CGContextRelease(ctx);
    
    return image;
}

@end
