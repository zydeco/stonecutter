//
//  RNBitStream+VarData.m
//  Stonecutter
//
//  Created by Jesús A. Álvarez on 13/04/2018.
//  Copyright © 2018 namedfork. All rights reserved.
//

#import "RNBitStream+VarData.h"

@implementation RNBitStream (VarData)

- (BOOL)readVarData:(out NSData * __nullable * __nonnull)data error:(out NSError * __nullable * __nullable)error {
    uint32_t length = 0;
    
    if (![self readVarUInt32:&length error:error]) {
        return NO;
    }
    
    return [self readData:data withLength:length error:error];
}

@end
