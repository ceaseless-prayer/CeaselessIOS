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
@property (strong, nonatomic)  UIStoryboard *mainStoryboard;

- (DataViewController *)viewControllerAtIndex:(NSUInteger)index storyboard:(UIStoryboard *)storyboard;
- (NSUInteger)indexOfViewController:(DataViewController *)viewController;
- (void) removeControllerAtIndex: (NSUInteger) index;
- (NSInteger) modelCount;

@end

