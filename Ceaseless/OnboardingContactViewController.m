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
@property (weak, nonatomic) IBOutlet UIButton *notNowButton;

@end

@implementation OnboardingContactViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.allowContactsAccessButton.layer.cornerRadius = 5;
    self.allowContactsAccessButton.layer.masksToBounds = YES;
    self.allowContactsAccessButton.layer.borderWidth = 1;
    self.allowContactsAccessButton.layer.borderColor = UIColor.whiteColor.CGColor;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Helper

- (void)moveToNextPage {
    UIScrollView *scrollView = (UIScrollView *) self.view.superview;

    CGRect nextPageRect = scrollView.frame;
    nextPageRect.origin.x = nextPageRect.size.width * 2;
    nextPageRect.origin.y = 0;

    [scrollView scrollRectToVisible:nextPageRect animated:YES];
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
    [AppUtils requestAddressBookAccess];

    self.allowContactsAccessButton.enabled = NO;
    self.notNowButton.enabled = NO;

    // Need to give timeout to make the animation smoother
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self moveToNextPage];
    });
}

- (IBAction)notNowTouched:(id)sender {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:@(YES) forKey:kDoesSetupContactNeedToAskLater];
    [defaults synchronize];

    [self moveToNextPage];
}

@end
