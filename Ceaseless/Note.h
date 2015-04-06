//
//  Note.h
//  Ceaseless
//
//  Created by Christopher Lim on 4/1/15.
//  Copyright (c) 2015 Christopher Lim. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class PersonIdentifier;

@interface Note : NSManagedObject

@property (nonatomic, retain) NSDate * createDate;
@property (nonatomic, retain) NSDate * lastUpdatedDate;
@property (nonatomic, retain) NSString * text;
@property (nonatomic, retain) NSOrderedSet *peopleTagged;
@end

@interface Note (CoreDataGeneratedAccessors)

- (void)insertObject:(PersonIdentifier *)value inPeopleTaggedAtIndex:(NSUInteger)idx;
- (void)removeObjectFromPeopleTaggedAtIndex:(NSUInteger)idx;
- (void)insertPeopleTagged:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removePeopleTaggedAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInPeopleTaggedAtIndex:(NSUInteger)idx withObject:(PersonIdentifier *)value;
- (void)replacePeopleTaggedAtIndexes:(NSIndexSet *)indexes withPeopleTagged:(NSArray *)values;
- (void)addPeopleTaggedObject:(PersonIdentifier *)value;
- (void)removePeopleTaggedObject:(PersonIdentifier *)value;
- (void)addPeopleTagged:(NSOrderedSet *)values;
- (void)removePeopleTagged:(NSOrderedSet *)values;
@end
