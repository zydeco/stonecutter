//
//  ChunkCountFormatter.m
//  Stonecutter
//
//  Created by Jesús A. Álvarez on 20/05/2018.
//  Copyright © 2018 namedfork. All rights reserved.
//

#import "ChunkCountFormatter.h"

@implementation ChunkCountFormatter

+ (BOOL)allowsReverseTransformation {
    return NO;
}

+ (Class)transformedValueClass {
    return [NSString class];
}

- (id)transformedValue:(NSNumber *)value {
    return [NSString localizedStringWithFormat:@"%@ %@", value, value.integerValue == 1 ? @"chunk" : @"chunks"];
}

@end
