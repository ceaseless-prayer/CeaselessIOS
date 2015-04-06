//
//  AddressBookId.h
//  Ceaseless
//
//  Created by Christopher Lim on 4/3/15.
//  Copyright (c) 2015 Christopher Lim. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class PersonIdentifier, PersonInfo;

@interface AddressBookId : NSManagedObject

@property (nonatomic, retain) NSString * deviceId;
@property (nonatomic, retain) NSString * recordId;
@property (nonatomic, retain) PersonIdentifier *ceaselessContact;
@property (nonatomic, retain) NSSet *primaryIdFor;
@end

@interface AddressBookId (CoreDataGeneratedAccessors)

- (void)addPrimaryIdForObject:(PersonInfo *)value;
- (void)removePrimaryIdForObject:(PersonInfo *)value;
- (void)addPrimaryIdFor:(NSSet *)values;
- (void)removePrimaryIdFor:(NSSet *)values;

@end
