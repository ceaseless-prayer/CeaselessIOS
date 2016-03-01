//
//  SetupNotificationCollectionViewCell.m
//  Ceaseless
//
//  Created by Wilbert Liu on 2/29/16.
//  Copyright © 2016 Christopher Lim. All rights reserved.
//

#import "SetupNotificationCollectionViewCell.h"
#import "AppUtils.h"
#import "AppConstants.h"

@interface SetupNotificationCollectionViewCell ()

@property (weak, nonatomic) IBOutlet UIView *shadowView;
@property (weak, nonatomic) IBOutlet UIView *cardView;

@end

@implementation SetupNotificationCollectionViewCell

- (void)awakeFromNib {
    [AppUtils setupCardView:self.cardView withShadowView:self.shadowView];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Helpers

- (void)registerUserNotificationFinished {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.delegate setupNotificationFinished];
}

#pragma mark - Actions

- (IBAction)yesTouched:(id)sender {
    if ([UIApplication instancesRespondToSelector:@selector(registerUserNotificationSettings:)]) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(registerUserNotificationFinished)
                                                     name:@"RegisterNotificationFinished"
                                                   object:nil];

        [[UIApplication sharedApplication] registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert | UIUserNotificationTypeSound categories:nil]];
    }
}

- (IBAction)askMeLaterTouched:(id)sender {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:@(YES) forKey:kDoesSetupNotificationNeedToAskLater];
    [defaults synchronize];

    [self.delegate setupNotificationFinished];
}

@end
