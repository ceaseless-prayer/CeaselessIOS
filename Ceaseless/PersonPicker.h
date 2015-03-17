//
//  AddressBook.h
//  Ceaseless
//
//  Created by Lori Hill on 3/3/15.
//  Copyright (c) 2015 Christopher Lim. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AddressBookUI/AddressBookUI.h>
#import "Person.h"

@interface PersonPicker : NSObject

- (void)loadContacts;
- (void) refreshCeaselessContactsFromAddressBook: (ABAddressBookRef)addressBook;
- (Person *) getCeaselessContactFromABRecord: (ABRecordRef) rawPerson;
- (void) updateCeaselessContactFromABRecord: (ABRecordRef) rawPerson;
- (Person *) createCeaselessContactFromABRecord: (ABRecordRef) rawPerson;
- (NSArray *) getAllCeaselessContacts;
    
@end
