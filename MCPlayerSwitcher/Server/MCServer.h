//
//  MCServer.h
//  MCPlayerSwitcher
//
//  Created by Jesús A. Álvarez on 09/04/2018.
//  Copyright © 2018 namedfork. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MCServer;

@protocol MCServerDelegate

- (void)mcServer:(MCServer*)server didLogInUser:(nonnull NSUUID*)uuid withDisplayName:(nonnull NSString*)displayName;

@end

@interface MCServer : NSObject

@property (nonatomic, weak) id<MCServerDelegate> delegate;

- (void)run;
- (void)stop;

@end
