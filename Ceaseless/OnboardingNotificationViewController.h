//
//  OnboardingNotificationViewController.h
//  Ceaseless
//
//  Created by Wilbert Liu on 3/15/16.
//  Copyright © 2016 Christopher Lim. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol OnboardingDelegate <NSObject>

- (void)onboardingHasFinished;

@end

@interface OnboardingNotificationViewController : UIViewController

@property (weak, nonatomic) id<OnboardingDelegate> delegate;

@end
