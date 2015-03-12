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
@property (nonatomic, retain) NSArray *fetchedObjects;

- (void)requestDailyVerseReference;
- (void) manageScriptureQueue;
- (ScriptureQueue *) popScriptureQueue;
- (void) getScriptureWithPredicate: (NSString *) predicateArgument;
@end
