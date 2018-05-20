//
//  MCTypes.h
//  Stonecutter
//
//  Created by Jesús A. Álvarez on 17/05/2018.
//  Copyright © 2018 namedfork. All rights reserved.
//

#ifndef MCTypes_h
#define MCTypes_h

#ifdef __cplusplus
extern "C" {
#endif

typedef struct {int32_t x,z;} ChunkPos;

typedef enum : int32_t {
    MCDimensionOverworld = 0,
    MCDimensionNether = 1,
    MCDimensionEnd = 2,
} MCDimension;

typedef enum : uint8_t {
    MCChunkTagData2D = 45,
    MCChunkTagData2DLegacy = 46,
    MCChunkTagSubChunkPrefix = 47,
    MCChunkTagLegacyTerrain = 48,
    MCChunkTagBlockEntity = 49,
    MCChunkTagEntity = 50,
    MCChunkTagPendingTicks = 51,
    MCChunkTagBlockExtraData = 52,
    MCChunkTagBiomeState = 53,
    MCChunkTagFinalizedState = 54,
    MCChunkTagVersion = 118
} MCChunkTag;

bool IsValidChunkTag(uint8_t tag);
NSString * NSLocalizedStringFromDimension(MCDimension dim);

#ifdef __cplusplus
}
#endif

#endif /* MCTypes_h */
