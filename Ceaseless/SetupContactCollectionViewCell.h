//
//  SetupContactCollectionViewCell.h
//  Ceaseless
//
//  Created by Wilbert Liu on 2/29/16.
//  Copyright © 2016 Christopher Lim. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol SetupContactDelegate <NSObject>

- (void)setupContactFinished;

@end

@interface SetupContactCollectionViewCell : UICollectionViewCell

@property (weak, nonatomic) id <SetupContactDelegate> delegate;

@end
