//
//  SetupContactCollectionViewCell.m
//  Ceaseless
//
//  Created by Wilbert Liu on 2/29/16.
//  Copyright © 2016 Christopher Lim. All rights reserved.
//

#import "SetupContactCollectionViewCell.h"
#import "AppUtils.h"
#import "AppConstants.h"

@interface SetupContactCollectionViewCell ()

@property (weak, nonatomic) IBOutlet UIView *shadowView;
@property (weak, nonatomic) IBOutlet UIView *cardView;

@end

@implementation SetupContactCollectionViewCell

- (void)awakeFromNib {
    [AppUtils setupCardView:self.cardView withShadowView:self.shadowView];
}

#pragma mark - Actions

- (IBAction)allowAccessTouched:(id)sender {
    [AppUtils getAddressBookRef];
    [self.delegate setupContactFinished];
}

- (IBAction)askMeLaterTouched:(id)sender {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:@(YES) forKey:kDoesSetupContactNeedToAskLater];
    [defaults synchronize];

    [self.delegate setupContactFinished];
}

@end
