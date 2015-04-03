//
//  Email.h
//  Ceaseless
//
//  Created by Lori Hill on 3/10/15.
//  Copyright (c) 2015 Christopher Lim. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class PersonIdentifier;

@interface Email : NSManagedObject

@property (nonatomic, retain) NSString * address;
@property (nonatomic, retain) NSSet *person;
@end

@interface Email (CoreDataGeneratedAccessors)

- (void)addPersonObject:(PersonIdentifier *)value;
- (void)removePersonObject:(PersonIdentifier *)value;
- (void)addPerson:(NSSet *)values;
- (void)removePerson:(NSSet *)values;

@end
