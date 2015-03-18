//
//  PrayerRecord.h
//  Ceaseless
//
//  Created by Lori Hill on 3/10/15.
//  Copyright (c) 2015 Christopher Lim. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "PrayerRecordConstants.h"

@class Person;

@interface PrayerRecord : NSManagedObject

@property (nonatomic, retain) NSDate * createDate;
@property (nonatomic, retain) NSString * type;
@property (nonatomic, retain) Person *person;

@end
