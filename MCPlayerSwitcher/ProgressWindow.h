//
//  ProgressWindow.h
//  MCPlayerSwitcher
//
//  Created by Jesús A. Álvarez on 16/02/2018.
//  Copyright © 2018 namedfork. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ProgressWindow : NSWindow

@property (nonatomic, weak) IBOutlet NSProgressIndicator *progressBar;
@property (nonatomic, weak) IBOutlet NSTextField *progresLabel;
@property (nonatomic, weak) NSProgress *progress;
@property (nonatomic, weak) IBOutlet NSButton *cancelButton;

@end
