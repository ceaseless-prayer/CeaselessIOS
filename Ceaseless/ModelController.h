//
//  ModelController.h
//  Ceaseless
//
//  Created by Christopher Lim on 3/2/15.
//  Copyright (c) 2015 Christopher Lim. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PersonPicker.h"

@class DataViewController;

@interface ModelController : NSObject <UIPageViewControllerDataSource>

@property (strong, nonatomic) PersonPicker *personPicker;

- (DataViewController *)viewControllerAtIndex:(NSUInteger)index storyboard:(UIStoryboard *)storyboard;
- (NSUInteger)indexOfViewController:(DataViewController *)viewController;

@end

