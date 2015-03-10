//
//  Note.h
//  Ceaseless
//
//  Created by Lori Hill on 3/10/15.
//  Copyright (c) 2015 Christopher Lim. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Note : NSManagedObject

@property (nonatomic, retain) NSDate * createDate;
@property (nonatomic, retain) NSString * text;
@property (nonatomic, retain) NSDate * lastUpdatedDate;
@property (nonatomic, retain) NSSet *peopleTagged;
@end

@interface Note (CoreDataGeneratedAccessors)

- (void)addPeopleTaggedObject:(NSManagedObject *)value;
- (void)removePeopleTaggedObject:(NSManagedObject *)value;
- (void)addPeopleTagged:(NSSet *)values;
- (void)removePeopleTagged:(NSSet *)values;

@end
