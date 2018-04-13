//
//  NSData+ZLib.m
//  MCPlayerSwitcher
//
//  Created by Jesús A. Álvarez on 12/04/2018.
//  Copyright © 2018 namedfork. All rights reserved.
//

#import "NSData+ZLib.h"
#import <zlib.h>

#define CHUNK 4096

@implementation NSData (ZLib)

- (NSData *)inflatedData {
    z_stream strm;
    unsigned char outBuf[CHUNK];
    
    /* allocate inflate state */
    strm.zalloc = Z_NULL;
    strm.zfree = Z_NULL;
    strm.opaque = Z_NULL;
    strm.avail_in = 0;
    strm.next_in = Z_NULL;
    if (inflateInit(&strm) != Z_OK)
        return nil;
    
    strm.avail_in = (unsigned int)self.length;
    strm.next_in = (void*)self.bytes;
    
    NSMutableData *inflatedData = [NSMutableData dataWithCapacity:self.length];
    
    do {
        strm.avail_out = CHUNK;
        strm.next_out = outBuf;
        int ret = inflate(&strm, Z_NO_FLUSH);
        assert(ret != Z_STREAM_ERROR);  /* state not clobbered */
        switch (ret) {
            case Z_NEED_DICT:
                ret = Z_DATA_ERROR;     /* and fall through */
            case Z_DATA_ERROR:
            case Z_MEM_ERROR:
                inflateEnd(&strm);
                return nil;
        }
        
        [inflatedData appendBytes:outBuf length:CHUNK - strm.avail_out];
    } while (strm.avail_out == 0);
    
    inflateEnd(&strm);
    
    return inflatedData;
}

@end
