//
//  OnboardingNotificationViewController.m
//  Ceaseless
//
//  Created by Wilbert Liu on 3/15/16.
//  Copyright © 2016 Christopher Lim. All rights reserved.
//

#import "OnboardingNotificationViewController.h"
#import "AppConstants.h"

@interface OnboardingNotificationViewController ()

@property (weak, nonatomic) IBOutlet UIButton *turnOnNotificationsButton;

@end

@implementation OnboardingNotificationViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.turnOnNotificationsButton.layer.cornerRadius = 5;
    self.turnOnNotificationsButton.layer.masksToBounds = YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Helper

- (void)registerUserNotificationFinished {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.delegate onboardingHasFinished];
}

#pragma mark - Actions

- (IBAction)turnOnNotificationsTouched:(id)sender {
    if ([UIApplication instancesRespondToSelector:@selector(registerUserNotificationSettings:)]) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(registerUserNotificationFinished)
                                                     name:@"RegisterNotificationFinished"
                                                   object:nil];

        [[UIApplication sharedApplication] registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert | UIUserNotificationTypeSound categories:nil]];
    }
}

- (IBAction)notNowTouched:(id)sender {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:@(YES) forKey:kDoesSetupNotificationNeedToAskLater];
    [defaults synchronize];

    [self.delegate onboardingHasFinished];
}

@end
