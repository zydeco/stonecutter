//
//  WorldOperation.h
//  MCPlayerSwitcher
//
//  Created by Jesús A. Álvarez on 23/03/2018.
//  Copyright © 2018 namedfork. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WorldOperation : NSOperation

@property (strong) NSURL *source;
@property (strong) NSURL *destination;
@property (readonly) NSProgress *progress;
@property (strong) NSError *error;
@property (readonly) NSString *localizedName;

@end
