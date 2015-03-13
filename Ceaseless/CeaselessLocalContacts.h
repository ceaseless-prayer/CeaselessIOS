//
//  CeaselessContacts.h
//  Ceaseless
//
//  Created by Christopher Lim on 3/13/15.
//  Copyright (c) 2015 Christopher Lim. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CeaselessLocalContacts : NSObject
@property (strong, nonatomic) NSArray *contacts;
- (NSArray *) filterResults: (NSArray*) results byEmails:(NSSet*) emails orPhoneNumbers: (NSSet*) phoneNumber;
- (NSArray *) lookupContactsByFirstName:(NSString*) firstName andLastName: (NSString*) lastName;
- (NSArray *) lookupContactsByDeviceId: (NSString*) deviceId andAddressBookId:(NSString*) addressBookId;
@end
