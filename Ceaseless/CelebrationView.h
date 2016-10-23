//
//  CelebrationView.h
//  Ceaseless
//
//  Created by Lori Hill on 10/22/16.
//  Copyright © 2016 Christopher Lim. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CelebrationView : UIView

@property (strong, nonatomic) IBOutlet UIVisualEffectView *visualEffectView;
@property (strong, nonatomic) IBOutlet UIImageView *backgroundImageView;
@property (strong, nonatomic) IBOutlet UIView *cardView;
@property (strong, nonatomic) IBOutlet UIImageView *crownView;
@property (strong, nonatomic) IBOutlet UILabel *peopleCount;
@property (strong, nonatomic) IBOutlet UIButton *showMoreButton;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *loadingMore;
@property (strong, nonatomic) IBOutlet UIView *shadowView;
@property (strong, nonatomic) IBOutlet UIView *contentView;

@end
