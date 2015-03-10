//
//  ScripturePicker.h
//  Ceaseless
//
//  Created by Lori Hill on 3/5/15.
//  Copyright (c) 2015 Lori Hill. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "NonMOScripture.h"

@interface ScripturePicker : NSObject

@property (strong, nonatomic) NonMOScripture *scripture;

- (NonMOScripture *)requestDailyVerseReference;

@end
