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
}

- (instancetype)initWithKey:(NSString*)key data:(NSData*)data {
    if ((self = [super init])) {
        if ([key hasPrefix:@"player_"]) {
            _uuid = [[NSUUID alloc] initWithUUIDString:[key substringFromIndex:7]];
        }
        playerData = data;
        
        [self loadPlayerData];
    }
    return self;
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
    std::istringstream buf(std::string((const char*)playerData.bytes, (size_t)playerData.length));
    nbt::io::stream_reader reader(buf, endian::little);
    const auto root = reader.read_compound().second;
    
    // inventory
    auto inventory = root->at("Inventory").as<nbt::tag_list>();
    int16_t hotbar[9] = {0,0,0,0,0,0,0,0,0};
    for(auto i = inventory.begin(); i < inventory.end(); i++) {
        auto item = i->as<nbt::tag_compound>();
        int16_t slot = static_cast<int16_t>(item["Slot"]);
        int16_t itemId = static_cast<int16_t>(item["id"]);
        if (slot < 9 || slot > 17) continue;
        auto &tag = item["tag"];
        if (tag) {
            auto &ench = tag["ench"].as<nbt::tag_list>();
            if (ench.size() > 0) {
                itemId *= -1;
            }
        }
        hotbar[slot-9] = itemId;
    }
    _hotbarItems = [NSArray arrayWithObjects:@(hotbar[0]), @(hotbar[1]),
                   @(hotbar[2]), @(hotbar[3]), @(hotbar[4]), @(hotbar[5]),
                   @(hotbar[6]), @(hotbar[7]), @(hotbar[8]), nil];
    
    // attributes
    auto attributesList = root->at("Attributes").as<nbt::tag_list>();
    NSMutableDictionary<NSString*,NSNumber*> *attributes = [NSMutableDictionary dictionaryWithCapacity:attributesList.size()];
    for(auto i = attributesList.begin(); i < attributesList.end(); i++) {
        auto item = i->as<nbt::tag_compound>();
        std::string name = static_cast<std::string>(item["Name"]);
        float value = static_cast<float>(item["Current"]);
        attributes[@(name.c_str())] = @(value);
    }
    _attributeValues = attributes;
}

@end
