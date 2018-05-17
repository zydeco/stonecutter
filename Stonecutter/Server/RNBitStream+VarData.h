//
//  RNBitStream+VarData.h
//  Stonecutter
//
//  Created by Jesús A. Álvarez on 13/04/2018.
//  Copyright © 2018 namedfork. All rights reserved.
//

#import <RakNetWrapper/RakNetWrapper.h>

@interface RNBitStream (VarData)

- (BOOL)readVarData:(out NSData * __nullable * __nonnull)data error:(out NSError * __nullable * __nullable)error;

@end
