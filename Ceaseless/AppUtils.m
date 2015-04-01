//
//  Utils.m
//  Ceaseless
//
//  Created by Christopher Lim on 3/31/15.
//  Copyright (c) 2015 Christopher Lim. All rights reserved.
//

#import "AppUtils.h"

@implementation AppUtils
+ (UIImage *) getDynamicBackgroundImage {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentDirectory = [paths objectAtIndex:0];
    NSString *imagePath = [documentDirectory stringByAppendingPathComponent:kDynamicBackgroundImage];
    return [UIImage imageWithContentsOfFile:imagePath];
}
@end
