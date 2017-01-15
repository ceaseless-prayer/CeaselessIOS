//
//  ProgressView.h
//  Ceaseless
//
//  Created by Christopher Lim on 4/8/15.
//  Copyright (c) 2015 Christopher Lim. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ProgressView : UIView
@property (weak, nonatomic) IBOutlet UIView *cardView;
@property (weak, nonatomic) IBOutlet UIView *shadowView;
@property (weak, nonatomic) IBOutlet UIView *contentView;
@property (weak, nonatomic) IBOutlet UIProgressView *progressBar;
@property (weak, nonatomic) IBOutlet UIButton *showMoreButton;
@property (weak, nonatomic) IBOutlet UIButton *announcementButton;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *loadingMore;
@property (weak, nonatomic) IBOutlet UILabel *progressCaption;
@property (weak, nonatomic) IBOutlet UIButton *subscribeToMailingListButton;
@property (weak, nonatomic) IBOutlet UILabel *progressLabel;
@property (weak, nonatomic) IBOutlet UIImageView *backgroundImageView;
@property (weak, nonatomic) IBOutlet UILabel *dayCounterLabel;
@end
