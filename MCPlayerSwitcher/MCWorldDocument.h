//
//  Document.h
//  MCPlayerSwitcher
//
//  Created by Jesús A. Álvarez on 15/02/2018.
//  Copyright © 2018 namedfork. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class ProgressWindow;

@interface MCWorldDocument : NSDocument

@property (nonatomic, strong) IBOutlet ProgressWindow *progressWindow;

@end

