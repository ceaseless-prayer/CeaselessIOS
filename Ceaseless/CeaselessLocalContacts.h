//
//  CeaselessContacts.h
//  Ceaseless
//
//  Created by Christopher Lim on 3/13/15.
//  Copyright (c) 2015 Christopher Lim. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "Person.h"
#import "AddressBookId.h"
#import "Email.h"
#import "PhoneNumber.h"
#import "Name.h"

@interface CeaselessLocalContacts : NSObject
@property (strong, nonatomic) NSMutableArray *contacts;
@property (strong, nonatomic) NSMutableArray *names;
@property (strong, nonatomic) NSMutableArray *addressBookIds;
- (NSArray *) filterResults: (NSArray*) results byEmails:(NSSet*) emails orPhoneNumbers: (NSSet*) phoneNumber;
- (NSArray *) lookupContactsByFirstName:(NSString*) firstName andLastName: (NSString*) lastName;
- (NSArray *) lookupContactsByAddressBookId:(NSString*) addressBookId;
@end
