//
//  PersonInfo.h
//  Ceaseless
//
//  Created by Christopher Lim on 4/3/15.
//  Copyright (c) 2015 Christopher Lim. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class AddressBookId, Email, Name, PersonIdentifier, PhoneNumber;

@interface PersonInfo : NSManagedObject

@property (nonatomic, retain) NSDate * favoritedDate;
@property (nonatomic, retain) NSDate * removedDate;
@property (nonatomic, retain) PersonIdentifier *identifier;
@property (nonatomic, retain) PhoneNumber *primaryPhoneNumber;
@property (nonatomic, retain) Email *primaryEmail;
@property (nonatomic, retain) AddressBookId *primaryAddressBookId;
@property (nonatomic, retain) Name *primaryFirstName;
@property (nonatomic, retain) Name *primaryLastName;

@end
