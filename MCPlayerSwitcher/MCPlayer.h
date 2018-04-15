//
//  MCPlayer.h
//  MCPlayerSwitcher
//
//  Created by Jesús A. Álvarez on 24/03/2018.
//  Copyright © 2018 namedfork. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MCPlayer : NSObject

@property (nonatomic, copy, nullable) NSUUID *uuid;
@property (nonatomic, readonly, nonnull) NSString *key;
@property (nonatomic, readonly, nonnull) NSData *data;
@property (nonatomic, readonly, nonnull) NSString *displayName;
@property (nonatomic, readonly, nonnull) NSArray<NSNumber*> *hotbarItems;
@property (nonatomic, readonly, nonnull) NSDictionary<NSString*,NSNumber*> *attributeValues;
@property (nonatomic, readonly, getter=isLocalPlayer) BOOL local;

- (instancetype)initWithKey:(nonnull NSString*)key data:(NSData*)data;
- (instancetype)cloneWithUUID:(nullable NSUUID*)uuid;

@end
