//
//  PerformActionOperation.m
//  Stonecutter
//
//  Created by Jesús A. Álvarez on 15/04/2018.
//  Copyright © 2018 namedfork. All rights reserved.
//

#import "PerformActionOperation.h"

@implementation PerformActionOperation

+ (instancetype)operationWithTarget:(id)target action:(SEL)action {
    PerformActionOperation *operation = [PerformActionOperation new];
    operation.target = target;
    operation.action = action;
    return operation;
}

- (void)main {
    [_target performSelector:_action withObject:self];
}

@end
