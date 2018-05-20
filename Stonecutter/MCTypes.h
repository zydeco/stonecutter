//
//  MCTypes.h
//  Stonecutter
//
//  Created by Jesús A. Álvarez on 17/05/2018.
//  Copyright © 2018 namedfork. All rights reserved.
//

#ifndef MCTypes_h
#define MCTypes_h

typedef struct {int32_t x,z;} ChunkPos;

typedef enum : int32_t {
    MCDimensionOverworld = 0,
    MCDimensionNether = 1,
    MCDimensionEnd = 2,
} MCDimension;

#endif /* MCTypes_h */
