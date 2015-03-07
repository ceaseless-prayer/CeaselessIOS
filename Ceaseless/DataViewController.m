//
//  DataViewController.m
//  Ceaseless
//
//  Created by Christopher Lim on 3/2/15.
//  Copyright (c) 2015 Christopher Lim. All rights reserved.
//

#import "DataViewController.h"
#import "PersonViewController.h"
#import "ScriptureViewController.h"

@implementation DataViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
	
	NSLog (@"index is %lu", (unsigned long)self.index);

    //format properly
	self.view.layer.cornerRadius = 6.0f;
	[self.view setClipsToBounds:YES];
    
	// drop shadow
	[self putView:self.view insideShadowWithColor:[UIColor yellowColor] andBlur: (CGFloat) 5.0f andOffset:CGSizeMake(1.0f, 1.75f) andOpacity: 0.5f];

}
- (void)putView:(UIView*)view insideShadowWithColor:(UIColor*)color andBlur: (CGFloat)blur andOffset:(CGSize)shadowOffset andOpacity:(CGFloat)shadowOpacity
{

	self.shadowView.backgroundColor = color;
	self.shadowView.userInteractionEnabled = NO; // Modify this if needed
	self.shadowView.layer.shadowColor = color.CGColor;
	self.shadowView.layer.shadowOffset = shadowOffset;
	self.shadowView.layer.shadowRadius = blur;
	self.shadowView.layer.cornerRadius = view.layer.cornerRadius;
	self.shadowView.layer.masksToBounds = NO;
	self.shadowView.clipsToBounds = NO;
	self.shadowView.layer.shadowOpacity = shadowOpacity;
	[self.shadowView removeFromSuperview];
	[view.superview insertSubview: self.shadowView belowSubview:view];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)setDynamicViewConstraintsForSubview: (UIView *) newSubview {
    [newSubview setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    [self.cardView addConstraint:[NSLayoutConstraint constraintWithItem:newSubview
                                                              attribute:NSLayoutAttributeTop
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:self.cardView
                                                              attribute:NSLayoutAttributeTop
                                                             multiplier:1.0
                                                               constant:0.0]];
    
    [self.cardView addConstraint:[NSLayoutConstraint constraintWithItem:newSubview
                                                              attribute:NSLayoutAttributeLeading
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:self.cardView
                                                              attribute:NSLayoutAttributeLeading
                                                             multiplier:1.0
                                                               constant:0.0]];
    
    [self.cardView addConstraint:[NSLayoutConstraint constraintWithItem:newSubview
                                                              attribute:NSLayoutAttributeBottom
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:self.cardView
                                                              attribute:NSLayoutAttributeBottom
                                                             multiplier:1.0
                                                               constant:0.0]];
    
    [self.cardView addConstraint:[NSLayoutConstraint constraintWithItem:newSubview
                                                              attribute:NSLayoutAttributeTrailing
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:self.cardView
                                                              attribute:NSLayoutAttributeTrailing
                                                             multiplier:1.0
                                                               constant:0.0]];
}

@end
