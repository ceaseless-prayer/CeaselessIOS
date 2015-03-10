//
//  PeopleQueue.h
//  Ceaseless
//
//  Created by Lori Hill on 3/10/15.
//  Copyright (c) 2015 Christopher Lim. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface PeopleQueue : NSManagedObject

@property (nonatomic, retain) NSManagedObject *person;

@end
