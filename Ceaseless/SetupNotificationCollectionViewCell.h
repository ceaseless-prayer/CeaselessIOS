//
//  SetupNotificationCollectionViewCell.h
//  Ceaseless
//
//  Created by Wilbert Liu on 2/29/16.
//  Copyright © 2016 Christopher Lim. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol SetupNotificationDelegate <NSObject>

- (void)setupNotificationFinished;

@end

@interface SetupNotificationCollectionViewCell : UICollectionViewCell

@property (weak, nonatomic) id <SetupNotificationDelegate> delegate;

@end
