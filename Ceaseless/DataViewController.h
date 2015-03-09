//
//  DataViewController.h
//  Ceaseless
//
//  Created by Christopher Lim on 3/2/15.
//  Copyright (c) 2015 Christopher Lim. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DataViewController : UIViewController

@property (strong, nonatomic) id dataObject;
@property (nonatomic) NSUInteger index;

- (void) formatCardView: (UIView *) cardView withShadowView: (UIView *) shadowView;
@end

