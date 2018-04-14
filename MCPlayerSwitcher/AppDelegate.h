//
//  AppDelegate.h
//  MCPlayerSwitcher
//
//  Created by Jesús A. Álvarez on 15/02/2018.
//  Copyright © 2018 namedfork. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class DocumentController;

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (nonatomic, readonly) DocumentController *documentController;
@property (nonatomic, strong) IBOutlet NSWindow *serverWindow;
@property (nonatomic, strong) IBOutlet NSTextView *serverLogView;

+ (instancetype)sharedInstance;
- (void)showServer;

@end
