//
//  CeaselessContacts.m
//  Ceaseless
//
//  Created by Christopher Lim on 3/13/15.
//  Copyright (c) 2015 Christopher Lim. All rights reserved.
//

#import "CeaselessLocalContacts.h"

@implementation CeaselessLocalContacts
- (NSArray *) filterResults: (NSArray*) results byEmails:(NSSet*) emails orPhoneNumbers: (NSSet*) phoneNumbers {
    NSMutableArray *filteredResults = [[NSMutableArray alloc]init];
    
    NSPredicate *getEmailObj = [NSPredicate predicateWithFormat:@"address IN %@", emails];
    NSPredicate *getPhoneNumberObj = [NSPredicate predicateWithFormat:@"number IN %@", phoneNumbers];
    
    for (Person *contact in results) {
        
        NSSet *matchingEmails = [contact.emails filteredSetUsingPredicate: getEmailObj];
        NSSet *matchingPhoneNumbers = [contact.phoneNumbers filteredSetUsingPredicate: getPhoneNumberObj];
        
        if([matchingEmails count] > 0 || [matchingPhoneNumbers count] > 0) {
            [filteredResults addObject:contact];
        }
    }
    
    return filteredResults;
}

- (NSArray *) lookupContactsByFirstName:(NSString*) firstName andLastName: (NSString*) lastName {
    NSMutableArray *results = [[NSMutableArray alloc]init];
    NSPredicate *getFirstNameObj = [NSPredicate predicateWithFormat:@"name = %@", firstName];
    NSPredicate *getLastNameObj = [NSPredicate predicateWithFormat:@"name = %@", lastName];
    NSArray* firstNameObj = [_names filteredArrayUsingPredicate:getFirstNameObj];
    NSArray* lastNameObj = [_names filteredArrayUsingPredicate:getLastNameObj];
    
    if([firstNameObj count] > 0 && [lastNameObj count] > 0) {
        NSPredicate *namePredicate = [NSPredicate predicateWithFormat: @"%@ IN firstNames AND %@ IN lastNames", firstNameObj[0], lastNameObj[0]];
        results = [[NSMutableArray alloc]initWithArray:[_contacts filteredArrayUsingPredicate: namePredicate]];
    }
    
    return results;
}

- (NSArray *) lookupContactsByAddressBookId:(NSString*) addressBookId {
    NSMutableArray *results = [[NSMutableArray alloc]init];
    NSUUID *oNSUUID = [[UIDevice currentDevice] identifierForVendor];
    NSString *deviceId = [oNSUUID UUIDString];
    
    NSPredicate *getAddressBookIdObj = [NSPredicate predicateWithFormat:
                                        @"recordId = %@ AND deviceId = %@", addressBookId, deviceId];
    NSArray *addressBookIdObj = [_addressBookIds filteredArrayUsingPredicate:getAddressBookIdObj];
    
    if([addressBookIdObj count] > 0) {
        NSPredicate *idPredicate = [NSPredicate predicateWithFormat: @"%@ IN addressBookIds", addressBookIdObj[0]];
        results = [[NSMutableArray alloc]initWithArray:[_contacts filteredArrayUsingPredicate: idPredicate]];
    }
    
    return results;
}
@end
