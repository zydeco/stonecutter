//
//  ProgressWindow.m
//  Stonecutter
//
//  Created by Jesús A. Álvarez on 16/02/2018.
//  Copyright © 2018 namedfork. All rights reserved.
//

#import "ProgressWindow.h"

@implementation ProgressWindow
{
    NSProgress *_progress;
}

- (void)setProgress:(NSProgress *)progress {
    NSArray<NSString*> *keys = @[@"fractionCompleted", @"indeterminate", @"cancellable"];
    for (NSString *key in keys) {
        [_progress removeObserver:self forKeyPath:key];
        [progress addObserver:self forKeyPath:key options:0 context:NULL];
    }
    _progress = progress;
    [self updateProgressBar];
}

- (NSProgress *)progress {
    return _progress;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if (object == _progress) {
        [self performSelectorOnMainThread:@selector(updateProgressBar) withObject:nil waitUntilDone:0];
    }
}

- (void)updateProgressBar {
    _progressBar.indeterminate = _progress.indeterminate;
    _progressBar.doubleValue = _progress.fractionCompleted;
    _cancelButton.enabled = _progress.cancellable;
}

- (IBAction)cancel:(id)sender {
    [_progress cancel];
}

@end
