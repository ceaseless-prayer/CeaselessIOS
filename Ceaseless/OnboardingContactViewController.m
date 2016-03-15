//
//  OnboardingContactViewController.m
//  Ceaseless
//
//  Created by Wilbert Liu on 3/15/16.
//  Copyright © 2016 Christopher Lim. All rights reserved.
//

#import "OnboardingContactViewController.h"
#import "AppUtils.h"
#import "AppConstants.h"
#import "Ceaseless-Swift.h"

@interface OnboardingContactViewController () <BWWalkthroughPage>

@property (weak, nonatomic) IBOutlet UIButton *allowContactsAccessButton;

@end

@implementation OnboardingContactViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.allowContactsAccessButton.layer.cornerRadius = 5;
    self.allowContactsAccessButton.layer.masksToBounds = YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - BWWalkthroughPage Delegate

- (void)walkthroughDidScroll:(CGFloat)position offset:(CGFloat)offset {
    if (offset == 1) {
        // The current visible view is this view
        UIScrollView *scrollView = (UIScrollView *) self.view.superview;
        scrollView.scrollEnabled = NO;
    }
}

#pragma mark - Actions

- (IBAction)allowContactsAccessTouched:(id)sender {
    [AppUtils getAddressBookRef];
}

- (IBAction)notNowTouched:(id)sender {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:@(YES) forKey:kDoesSetupContactNeedToAskLater];
    [defaults synchronize];
}

@end
