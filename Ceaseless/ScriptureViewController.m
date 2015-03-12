//
//  ScriptureViewController.m
//  Ceaseless
//
//  Created by Christopher Lim on 3/6/15.
//  Copyright (c) 2015 Christopher Lim. All rights reserved.
//

#import "ScriptureViewController.h"
#import "NonMOScripture.h"

@implementation ScriptureViewController

- (void)viewDidLoad {
	[super viewDidLoad];
		// Do any additional setup after loading the view, typically from a nib.
	[self formatCardView: self.scriptureView.cardView withShadowView:self.scriptureView.shadowView];
}
- (void)viewWillAppear: (BOOL)animated {
    [super viewWillAppear:animated];

	NonMOScripture *scripture = self.dataObject;
	self.scriptureView.scriptureReferenceLabel.text = scripture.citation;
	self.scriptureView.scriptureTextView.text = scripture.verse;
		//scroll text to top of view
	[self.scriptureView.scriptureTextView scrollRangeToVisible: (NSMakeRange(0, 0))];
}
@end
