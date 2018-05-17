//
//  PerformActionOperation.h
//  Stonecutter
//
//  Created by Jesús A. Álvarez on 15/04/2018.
//  Copyright © 2018 namedfork. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PerformActionOperation : NSOperation

+ (instancetype)operationWithTarget:(id)target action:(SEL)action;

@property (nonatomic, weak) id target;
@property (nonatomic, assign) SEL action;

@end
