//
//  PersonView.h
//  Ceaseless
//
//  Created by Lori Hill on 3/3/15.
//  Copyright (c) 2015 Christopher Lim. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PersonView : UIView
@property (strong, nonatomic) IBOutlet UIView *contentView;
@property (weak, nonatomic) IBOutlet UIImageView *personImageView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UIButton *moreButton;
@property (weak, nonatomic) IBOutlet UIVisualEffectView *blurEffect;

@end
