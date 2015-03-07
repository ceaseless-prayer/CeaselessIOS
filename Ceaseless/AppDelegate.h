//
//  AppDelegate.h
//  Ceaseless
//
//  Created by Christopher Lim on 3/2/15.
//  Copyright (c) 2015 Christopher Lim. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Scripture.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (nonatomic, strong) NSArray *peopleArray;
@property (nonatomic, strong) NSArray *cardArray;
@property (nonatomic, strong) Scripture *scripture;

@end

