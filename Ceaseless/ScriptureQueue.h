//
//  ScriptureQueue.h
//  Ceaseless
//
//  Created by Lori Hill on 3/10/15.
//  Copyright (c) 2015 Christopher Lim. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface ScriptureQueue : NSManagedObject

@property (nonatomic, retain) NSString * verse;
@property (nonatomic, retain) NSString * citation;
@property (nonatomic, retain) NSString * shareLink;
@property (nonatomic, retain)	NSDate * lastPresentedDate;

- (void) seedDefaultScripture;
- (NSInteger) countObjectsInCoreData;
@end
