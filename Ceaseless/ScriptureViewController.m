//
//  ScriptureViewController.m
//  Ceaseless
//
//  Created by Christopher Lim on 3/6/15.
//  Copyright (c) 2015 Christopher Lim. All rights reserved.
//

#import "ScriptureViewController.h"
#import "Scripture.h"

@implementation ScriptureViewController

- (void)viewWillAppear: (BOOL)animated {
    [super viewWillAppear:animated];
    if (self.index == 0) {
        Scripture *scripture = self.dataObject;
        self.scriptureView.scriptureReferenceLabel.text = scripture.citation;
        self.scriptureView.scriptureTextView.text = scripture.verse;
    }
}
@end
