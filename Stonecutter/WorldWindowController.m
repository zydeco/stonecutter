//
//  WorldWindowController.m
//  Stonecutter
//
//  Created by Jesús A. Álvarez on 20/05/2018.
//  Copyright © 2018 namedfork. All rights reserved.
//

#import "WorldWindowController.h"
#import "MCWorldDocument.h"

@interface WorldWindowController ()

@end

@implementation WorldWindowController

@dynamic document;

- (void)windowDidLoad {
    [super windowDidLoad];
    
    self.worldView.chunks = [self.document chunksForDimension:self.dimension];
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

- (NSString *)windowTitleForDocumentDisplayName:(NSString *)displayName {
    return [NSString stringWithFormat: @"%@ – %@", displayName, NSLocalizedStringFromDimension(self.dimension)];
}

@end
