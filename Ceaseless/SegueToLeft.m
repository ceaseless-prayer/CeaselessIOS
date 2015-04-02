//
//  SegueToLeft.m
//  Ceaseless
//
//  Created by Lori Hill on 4/2/15.
//  Copyright (c) 2015 Christopher Lim. All rights reserved.
//

#import "SegueToLeft.h"
#import "QuartzCore/QuartzCore.h"

@implementation SegueToLeft
-(void)perform {

	UIViewController *sourceViewController = (UIViewController*)[self sourceViewController];
	UIViewController *destinationController = (UIViewController*)[self destinationViewController];

	CATransition* transition = [CATransition animation];
	transition.duration = .25;
	transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
	transition.type = kCATransitionPush; //kCATransitionMoveIn; //, kCATransitionPush, kCATransitionReveal, kCATransitionFade
	transition.subtype = kCATransitionFromLeft; //kCATransitionFromLeft, kCATransitionFromRight, kCATransitionFromTop, kCATransitionFromBottom



	[sourceViewController.navigationController.view.layer addAnimation:transition
																forKey:kCATransition];

	[sourceViewController.navigationController pushViewController:destinationController animated:NO];

}
@end
