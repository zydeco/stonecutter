//
//  MCTypes.m
//  Stonecutter
//
//  Created by Jesús A. Álvarez on 20/05/2018.
//  Copyright © 2018 namedfork. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MCTypes.h"

bool IsValidChunkTag(uint8_t tag) {
    return (tag == MCChunkTagVersion || (tag >= MCChunkTagData2D && tag <= MCChunkTagFinalizedState));
}

NSString * NSLocalizedStringFromDimension(MCDimension dim) {
    switch (dim) {
        case MCDimensionOverworld:
            return NSLocalizedString(@"Overworld", @"Name for dimension Overworld");
        case MCDimensionNether:
            return NSLocalizedString(@"Nether", @"Name for dimension Nether");
        case MCDimensionEnd:
            return NSLocalizedString(@"End", @"Name for dimension End");
        default:
            return [NSString stringWithFormat:@"dimension %d", dim];
    }
}
