//
//  WelcomeCollectionViewCell.m
//  Ceaseless
//
//  Created by Wilbert Liu on 2/26/16.
//  Copyright © 2016 Christopher Lim. All rights reserved.
//

#import "WelcomeCollectionViewCell.h"
#import "AppUtils.h"

@interface WelcomeCollectionViewCell ()

@property (weak, nonatomic) IBOutlet UIView *shadowCardView;
@property (weak, nonatomic) IBOutlet UIView *cardView;

@end

@implementation WelcomeCollectionViewCell

- (void)awakeFromNib {
    [AppUtils setupCardView:self.cardView withShadowView:self.shadowCardView];
}

@end
