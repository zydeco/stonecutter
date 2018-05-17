//
//  WorldOperation.m
//  Stonecutter
//
//  Created by Jesús A. Álvarez on 23/03/2018.
//  Copyright © 2018 namedfork. All rights reserved.
//

#import "WorldOperation.h"
#import "RSWeakifySelf.h"

@implementation WorldOperation

- (instancetype)init {
    self = [super init];
    if (self) {
        _progress = [NSProgress progressWithTotalUnitCount:0];
        _progress.cancellationHandler = weakifySelf(^{
            [self cancel];
        });
        _error = nil;
    }
    return self;
}

@end
