//
//  PhoneNumber.h
//  Ceaseless
//
//  Created by Lori Hill on 3/10/15.
//  Copyright (c) 2015 Christopher Lim. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface PhoneNumber : NSManagedObject

@property (nonatomic, retain) NSString * number;
@property (nonatomic, retain) NSSet *person;
@end

@interface PhoneNumber (CoreDataGeneratedAccessors)

- (void)addPersonObject:(NSManagedObject *)value;
- (void)removePersonObject:(NSManagedObject *)value;
- (void)addPerson:(NSSet *)values;
- (void)removePerson:(NSSet *)values;

@end
