//
//  ScripturePicker.h
//  Ceaseless
//
//  Created by Lori Hill on 3/5/15.
//  Copyright (c) 2015 Lori Hill. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "ScriptureQueue.h"

@interface ScripturePicker : NSObject

@property (strong, nonatomic) ScriptureQueue *scripture;

- (void)requestDailyVerseReference;
- (void) manageScriptureQueue;
- (ScriptureQueue *) popScriptureQueue;
- (NSArray *) getScriptureWithPredicate: (NSString *) predicateArgument;
@end
