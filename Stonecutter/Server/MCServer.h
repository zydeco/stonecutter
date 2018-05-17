//
//  MCServer.h
//  Stonecutter
//
//  Created by Jesús A. Álvarez on 09/04/2018.
//  Copyright © 2018 namedfork. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MCServer;

@protocol MCServerDelegate

@optional

- (void)mcServerDidStart:(MCServer*)server;
- (void)mcServerDidStop:(MCServer*)server;
- (void)mcServer:(MCServer*)server didLogInUser:(nonnull NSUUID*)uuid withDisplayName:(nonnull NSString*)displayName;

@end

@interface MCServer : NSObject

@property (nonatomic, weak) NSObject<MCServerDelegate>* delegate;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *worldName;


- (void)run;
- (void)stop;

@end
