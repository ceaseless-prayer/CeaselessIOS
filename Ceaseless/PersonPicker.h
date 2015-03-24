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
#import "NonMOPerson.h"

@interface PersonPicker : NSObject

- (void)loadContacts;
- (Person *) getCeaselessContactFromABRecord: (ABRecordRef) rawPerson;
- (Person *) getCeaselessContactFromCeaselessId: (NSString *) ceaselessId;
- (void) updateCeaselessContactFromABRecord: (ABRecordRef) rawPerson;
- (Person *) createCeaselessContactFromABRecord: (ABRecordRef) rawPerson;
- (NSArray *) getAllCeaselessContacts;
- (NonMOPerson *) getNonMOPersonForCeaselessContact: (Person*) person;
- (NSArray *) queuedPeople;
    
@end
