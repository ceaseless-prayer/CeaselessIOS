//
//  Email.h
//  Ceaseless
//
//  Created by Christopher Lim on 4/3/15.
//  Copyright (c) 2015 Christopher Lim. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class PersonIdentifier, PersonInfo;

@interface Email : NSManagedObject

@property (nonatomic, retain) NSString * address;
@property (nonatomic, retain) NSSet *person;
@property (nonatomic, retain) NSSet *primaryFor;
@end

@interface Email (CoreDataGeneratedAccessors)

- (void)addPersonObject:(PersonIdentifier *)value;
- (void)removePersonObject:(PersonIdentifier *)value;
- (void)addPerson:(NSSet *)values;
- (void)removePerson:(NSSet *)values;

- (void)addPrimaryForObject:(PersonInfo *)value;
- (void)removePrimaryForObject:(PersonInfo *)value;
- (void)addPrimaryFor:(NSSet *)values;
- (void)removePrimaryFor:(NSSet *)values;

@end
