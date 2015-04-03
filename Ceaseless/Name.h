//
//  Name.h
//  Ceaseless
//
//  Created by Christopher Lim on 4/3/15.
//  Copyright (c) 2015 Christopher Lim. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class PersonIdentifier, PersonInfo;

@interface Name : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSSet *firstNameFor;
@property (nonatomic, retain) NSSet *lastNameFor;
@property (nonatomic, retain) NSSet *primaryFirstNameFor;
@property (nonatomic, retain) NSSet *primaryLastNameFor;
@end

@interface Name (CoreDataGeneratedAccessors)

- (void)addFirstNameForObject:(PersonIdentifier *)value;
- (void)removeFirstNameForObject:(PersonIdentifier *)value;
- (void)addFirstNameFor:(NSSet *)values;
- (void)removeFirstNameFor:(NSSet *)values;

- (void)addLastNameForObject:(PersonIdentifier *)value;
- (void)removeLastNameForObject:(PersonIdentifier *)value;
- (void)addLastNameFor:(NSSet *)values;
- (void)removeLastNameFor:(NSSet *)values;

- (void)addPrimaryFirstNameForObject:(PersonInfo *)value;
- (void)removePrimaryFirstNameForObject:(PersonInfo *)value;
- (void)addPrimaryFirstNameFor:(NSSet *)values;
- (void)removePrimaryFirstNameFor:(NSSet *)values;

- (void)addPrimaryLastNameForObject:(PersonInfo *)value;
- (void)removePrimaryLastNameForObject:(PersonInfo *)value;
- (void)addPrimaryLastNameFor:(NSSet *)values;
- (void)removePrimaryLastNameFor:(NSSet *)values;

@end
