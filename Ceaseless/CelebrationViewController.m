//
//  CelebrationViewController.m
//  Ceaseless
//
//  Created by Lori Hill on 10/22/16.
//  Copyright © 2016 Christopher Lim. All rights reserved.
//

#import "CelebrationViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "UIView+Glow.h"
#import "AppUtils.h"

@interface CelebrationViewController ()

@end

@implementation CelebrationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIImage *backgroundImage = [AppUtils getDynamicBackgroundImage];
    if(backgroundImage != nil) {
        self.celebrationView.backgroundImageView.image = backgroundImage;
    }
    
    [self formatCardView: self.celebrationView.cardView withShadowView:self.celebrationView.shadowView];
    
    self.celebrationView.showMoreButton.layer.cornerRadius = 2.0f;
    self.celebrationView.showMoreButton.layer.borderWidth = 1.0f;
    self.celebrationView.showMoreButton.layer.borderColor = [UIColor whiteColor].CGColor;
    
    NSArray *progress = (NSArray *) self.dataObject;
    NSNumber *totalPeople = progress[1];
    self.celebrationView.peopleCount.text = [NSString stringWithFormat: @"%@", totalPeople];
    
    NSString *localInstallationId = [AppUtils localInstallationId];

    [AppUtils postAnalyticsEventWithCategory:@"celebration_view" andAction:@"post_total_active_ceaseless_contacts" andLabel:localInstallationId andValue: totalPeople];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.screenName = @"CelebrationViewScreen";
    CGPoint crownViewCenter = CGPointMake(CGRectGetMidX(self.celebrationView.crownView.bounds),
                                        CGRectGetMidY(self.celebrationView.crownView.bounds));
    [self.celebrationView.crownView glowOnceAtLocation:crownViewCenter inView:self.celebrationView.crownView];

//    [self.celebrationView startGlowingWithColor:[UIColor whiteColor] intensity:.08f];
//    [self.celebrationView.crownView startGlowing];
    self.celebrationView.loadingMore.hidden=YES;
}

- (IBAction)showMorePeople:(id)sender {
    self.celebrationView.showMoreButton.hidden = YES;
    [self.celebrationView.loadingMore startAnimating];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSNumber *numberOfPeople = [NSNumber numberWithInteger:[defaults integerForKey:kDailyPersonCount]];
    [AppUtils postAnalyticsEventWithCategory:@"celebration_view" andAction:@"button_press" andLabel:@"show_more_people" andValue: numberOfPeople];
    [[NSNotificationCenter defaultCenter] postNotificationName:kForceShowNewContent object:nil];
}

@end
