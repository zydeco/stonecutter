//
//  MCPlayer.m
//  Stonecutter
//
//  Created by Jesús A. Álvarez on 24/03/2018.
//  Copyright © 2018 namedfork. All rights reserved.
//

#import "MCPlayer.h"
#import "NBTKit/NBTKit.h"

@implementation MCPlayer
{
    NSData *playerData;
}

- (instancetype)initWithKey:(NSString*)key data:(NSData*)data {
    if ((self = [super init])) {
        if ([key hasPrefix:@"player_"]) {
            _uuid = [[NSUUID alloc] initWithUUIDString:[key substringFromIndex:7]];
        }
        playerData = data.copy;
        
        [self loadPlayerData];
    }
    return self;
}

- (instancetype)cloneWithUUID:(NSUUID *)cloneUUID {
    NSString *cloneKey = cloneUUID ? [NSString stringWithFormat:@"player_%@", cloneUUID.UUIDString.lowercaseString] : @"~local_player";
    return [[MCPlayer alloc] initWithKey:cloneKey data:playerData];
}

- (NSData *)data {
    return playerData;
}

- (NSString *)key {
    if (_uuid == nil) {
        return @"~local_player";
    } else {
        return [NSString stringWithFormat:@"player_%@", _uuid.UUIDString.lowercaseString];
    }
}

- (BOOL)isLocalPlayer {
    return _uuid == nil;
}

- (NSString *)displayName {
    if (_uuid) {
        return _uuid.UUIDString;
    } else {
        return @"<local player>";
    }
}

- (void)loadPlayerData {
    NSDictionary *nbt = [NBTKit NBTWithData:playerData name:NULL options:NBTLittleEndian error:NULL];
    NSLog(@"Player %@: %@", self.displayName, nbt);
    
    // inventory
    int16_t hotbar[9] = {0,0,0,0,0,0,0,0,0};
    int firstHotbarSlot = nbt[@"InventoryVersion"] ? 0 : 9;
    for (NSDictionary *item in nbt[@"Inventory"]) {
        int16_t slot = [item[@"Slot"] shortValue];
        int16_t itemID = [item[@"id"] shortValue];
        BOOL enchanted = [[item valueForKeyPath:@"tag.ench"] count] > 0;
        if (enchanted) {
            itemID *= -1;
        }
        int hotbarSlot = slot - firstHotbarSlot;
        if (hotbarSlot >= 0 && hotbarSlot < 9) {
            hotbar[hotbarSlot] = itemID;
        }
    }
    _hotbarItems = [NSArray arrayWithObjects:@(hotbar[0]), @(hotbar[1]),
                   @(hotbar[2]), @(hotbar[3]), @(hotbar[4]), @(hotbar[5]),
                   @(hotbar[6]), @(hotbar[7]), @(hotbar[8]), nil];
    
    // attributes
    NSArray<NSDictionary*> *attributesList = nbt[@"Attributes"];
    NSMutableDictionary<NSString*,NSNumber*> *attributes = [NSMutableDictionary dictionaryWithCapacity:attributesList.count];
    for (NSDictionary *attribute in attributesList) {
        attributes[attribute[@"Name"]] = attribute[@"Current"];
    }
    _attributeValues = attributes.copy;
}

@end
