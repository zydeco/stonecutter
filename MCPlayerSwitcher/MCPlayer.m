//
//  MCPlayer.m
//  MCPlayerSwitcher
//
//  Created by Jesús A. Álvarez on 24/03/2018.
//  Copyright © 2018 namedfork. All rights reserved.
//

#import "MCPlayer.h"

@implementation MCPlayer
{
    NSData *playerData;
}

- (instancetype)initWithKey:(NSString*)key data:(NSData*)data {
    if ((self = [super init])) {
        if ([key hasPrefix:@"player_"]) {
            _uuid = [[NSUUID alloc] initWithUUIDString:[key substringFromIndex:7]];
        }
        playerData = data;
    }
    return self;
}

- (NSString *)displayName {
    if (_uuid) {
        return _uuid.UUIDString;
    } else {
        return @"<local player>";
    }
}

@end
