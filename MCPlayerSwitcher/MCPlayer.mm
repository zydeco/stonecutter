//
//  MCPlayer.m
//  MCPlayerSwitcher
//
//  Created by Jesús A. Álvarez on 24/03/2018.
//  Copyright © 2018 namedfork. All rights reserved.
//

#import "MCPlayer.h"

#include "nbt_tags.h"
#include "libnbtplusplus/include/io/stream_reader.h"
#include <fstream>
#include <iostream>

@implementation MCPlayer
{
    NSData *playerData;
    NSArray<NSNumber*> *hotbarItems;
}

- (instancetype)initWithKey:(NSString*)key data:(NSData*)data {
    if ((self = [super init])) {
        if ([key hasPrefix:@"player_"]) {
            _uuid = [[NSUUID alloc] initWithUUIDString:[key substringFromIndex:7]];
        }
        playerData = data;
        
        std::istringstream buf(std::string((const char*)data.bytes, (size_t)data.length));
        nbt::io::stream_reader reader(buf, endian::little);
        auto inventory = reader.read_compound().second->at("Inventory").as<nbt::tag_list>();
        int16_t hotbar[9] = {0,0,0,0,0,0,0,0,0};
        for(auto i = inventory.begin(); i < inventory.end(); i++) {
            auto item = i->as<nbt::tag_compound>();
            int16_t slot = static_cast<int16_t>(item["Slot"]);
            int16_t itemId = static_cast<int16_t>(item["id"]);
            if (slot >= 9 && slot <= 17) {
                hotbar[slot-9] = itemId;
            }
        }
        hotbarItems = [NSArray arrayWithObjects:@(hotbar[0]), @(hotbar[1]),
                       @(hotbar[2]), @(hotbar[3]), @(hotbar[4]), @(hotbar[5]),
                       @(hotbar[6]), @(hotbar[7]), @(hotbar[8]), nil];
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

- (NSArray *)hotbarItems {
    return hotbarItems;
}

@end
