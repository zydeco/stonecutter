//
//  DocumentController.h
//  Stonecutter
//
//  Created by Jesús A. Álvarez on 15/02/2018.
//  Copyright © 2018 namedfork. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface DocumentController : NSDocumentController

- (NSURL *)urlForUnpackingWorld:(NSURL*)worldURL;
- (void)cleanupTemporaryFiles;

@end
