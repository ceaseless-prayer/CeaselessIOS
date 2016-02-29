//
//  WelcomeCollectionViewCell.m
//  Ceaseless
//
//  Created by Wilbert Liu on 2/26/16.
//  Copyright © 2016 Christopher Lim. All rights reserved.
//

#import "WelcomeCollectionViewCell.h"

@interface WelcomeCollectionViewCell ()

@property (weak, nonatomic) IBOutlet UIView *shadowCardView;
@property (weak, nonatomic) IBOutlet UIView *cardView;

@end

@implementation WelcomeCollectionViewCell

- (void)awakeFromNib {
    self.cardView.layer.cornerRadius = 24.0;
    self.cardView.clipsToBounds = YES;

    self.shadowCardView.layer.shadowColor = [UIColor blackColor].CGColor;
    self.shadowCardView.layer.shadowOffset = CGSizeMake(1, 1);
    self.shadowCardView.layer.shadowRadius = 4.0;
    self.shadowCardView.layer.cornerRadius = 24.0;
    self.shadowCardView.layer.shadowOpacity = 0.8;
}

@end
