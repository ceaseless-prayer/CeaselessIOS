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
}

- (void) formatCardView: (UIView *) cardView withShadowView: (UIView *) shadowView {
    //format properly
	cardView.layer.cornerRadius = 6.0f;
	[cardView setClipsToBounds:YES];
    
	// drop shadow
	[self putView:cardView insideShadowView: shadowView WithColor:[UIColor blackColor] andBlur: (CGFloat) 5.0f andOffset:CGSizeMake(1.0f, 1.75f) andOpacity: 0.5f];

}
- (void)putView:(UIView*)view insideShadowView: (UIView*) shadowView WithColor:(UIColor*)color andBlur: (CGFloat)blur andOffset:(CGSize)shadowOffset andOpacity:(CGFloat)shadowOpacity
{

	shadowView.backgroundColor = color;
	shadowView.userInteractionEnabled = NO; // Modify this if needed
	shadowView.layer.shadowColor = color.CGColor;
	shadowView.layer.shadowOffset = shadowOffset;
	shadowView.layer.shadowRadius = blur;
	shadowView.layer.cornerRadius = view.layer.cornerRadius;
	shadowView.layer.masksToBounds = NO;
	shadowView.clipsToBounds = NO;
	shadowView.layer.shadowOpacity = shadowOpacity;
	[shadowView removeFromSuperview];
	[view.superview insertSubview: shadowView belowSubview:view];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

}

@end
