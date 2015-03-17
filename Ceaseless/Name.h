//
//  Name.h
//  Ceaseless
//
//  Created by Christopher Lim on 3/13/15.
//  Copyright (c) 2015 Christopher Lim. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Person;

@interface Name : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSSet *firstNameFor;
@property (nonatomic, retain) NSSet *lastNameFor;
@end

@interface Name (CoreDataGeneratedAccessors)

- (void)addFirstNameForObject:(Person *)value;
- (void)removeFirstNameForObject:(Person *)value;
- (void)addFirstNameFor:(NSSet *)values;
- (void)removeFirstNameFor:(NSSet *)values;

- (void)addLastNameForObject:(Person *)value;
- (void)removeLastNameForObject:(Person *)value;
- (void)addLastNameFor:(NSSet *)values;
- (void)removeLastNameFor:(NSSet *)values;

@end
