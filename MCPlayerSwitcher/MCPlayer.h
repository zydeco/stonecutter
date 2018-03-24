//
//  MCPlayer.h
//  MCPlayerSwitcher
//
//  Created by Jesús A. Álvarez on 24/03/2018.
//  Copyright © 2018 namedfork. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MCPlayer : NSObject

@property (nonatomic, copy) NSUUID *uuid;
@property (nonatomic, readonly) NSString *displayName;

- (instancetype)initWithKey:(NSString*)key data:(NSData*)data;

@end
