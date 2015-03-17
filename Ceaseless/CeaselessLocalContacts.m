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
    for (Person *contact in results) {
        
        BOOL emailMatch = NO;
        BOOL phoneNumberMatch = NO;
        
        for(NSString *email in emails) {
            if([contact.emails containsObject:email]){
                emailMatch = YES;
                break;
            }
        }
        
        for(NSString *phoneNumber in phoneNumbers) {
            if([contact.phoneNumbers containsObject:phoneNumber]) {
                phoneNumberMatch = YES;
                break;
            };
        }
        
        if(emailMatch || phoneNumbers) {
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
    NSUUID *oNSUUID = [[UIDevice currentDevice] identifierForVendor];
    NSString *deviceId = [oNSUUID UUIDString];
    NSMutableArray *results = [[NSMutableArray alloc]init];
    for(Person *contact in _contacts) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:
                                  @"recordId = %@ AND deviceId = %@", addressBookId, deviceId];
        if(contact.addressBookIds != nil) {
        NSSet *idMatches = [contact.addressBookIds filteredSetUsingPredicate: predicate];
            if([idMatches count] > 0) {
                [results addObject: contact];
            }
        }
    }
    return results;
}
@end
