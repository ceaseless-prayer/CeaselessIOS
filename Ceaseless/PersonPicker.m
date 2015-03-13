//
//  AddressBook.m
//  Ceaseless
//
//  Created by Lori Hill on 3/3/15.
//  Copyright (c) 2015 Christopher Lim. All rights reserved.
//

#import "PersonPicker.h"
#import "NonMOPerson.h"
#import "AppDelegate.h"
#import "CeaselessLocalContacts.h"

@interface PersonPicker ()

@property (strong, nonatomic) NSMutableArray *ceaselessPeople;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@end

@implementation PersonPicker

- (instancetype) init {
    self = [super init];
    if (self) {
        AppDelegate *appDelegate = (id) [[UIApplication sharedApplication] delegate];
        self.managedObjectContext = appDelegate.managedObjectContext;
    }
    return self;
}

- (void) loadContacts {

	self.ceaselessPeople = [[NSMutableArray alloc] initWithCapacity: 3];
	ABAuthorizationStatus status = ABAddressBookGetAuthorizationStatus();

	if (status == kABAuthorizationStatusDenied) {
			// if you got here, user had previously denied/revoked permission for your
			// app to access the contacts, and all you can do is handle this gracefully,
			// perhaps telling the user that they have to go to settings to grant access
			// to contacts

		[[[UIAlertView alloc] initWithTitle:nil message:@"This app requires access to your contacts to function properly. Please visit to the \"Privacy\" section in the iPhone Settings app." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
	}

	CFErrorRef error = NULL;
	ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, &error);

	if (error) {
		NSLog(@"ABAddressBookCreateWithOptions error: %@", CFBridgingRelease(error));
		if (addressBook) CFRelease(addressBook);
	}

	if (status == kABAuthorizationStatusNotDetermined) {

			// present the user the UI that requests permission to contacts ...
		ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error) {
			if (error) {
				NSLog(@"ABAddressBookRequestAccessWithCompletion error: %@", CFBridgingRelease(error));
			}

			if (granted) {
					// if they gave you permission, then just carry on

				[self pickPeopleInAddressBook:addressBook];

			} else {
					// however, if they didn't give you permission, handle it gracefully, for example...

				dispatch_async(dispatch_get_main_queue(), ^{
						// BTW, this is not on the main thread, so dispatch UI updates back to the main queue

					[[[UIAlertView alloc] initWithTitle:nil message:@"This app requires access to your contacts to function properly. Please visit to the \"Privacy\" section in the iPhone Settings app." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
				});

			}

			if (addressBook) CFRelease(addressBook);
		});

	} else if (status == kABAuthorizationStatusAuthorized) {
		[self pickPeopleInAddressBook:addressBook];
		if (addressBook) CFRelease(addressBook);
	}
	if ([self.ceaselessPeople count] > 0) {
		AppDelegate *appDelegate = (id) [[UIApplication sharedApplication] delegate];
		appDelegate.peopleArray = self.ceaselessPeople;

	}

}

- (NSArray *)getUnifiedAddressBookRecords:(ABAddressBookRef)addressBook
{
    // http://stackoverflow.com/questions/11351454/dealing-with-duplicate-contacts-due-to-linked-cards-in-ios-address-book-api
    NSMutableSet *unifiedRecordsSet = [NSMutableSet set];
    CFArrayRef sources = ABAddressBookCopyArrayOfAllSources(addressBook);
    NSLog(@" total sources:%ld", CFArrayGetCount(sources));
    for (CFIndex i=0; i < CFArrayGetCount(sources); i++) {
        ABRecordRef source = CFArrayGetValueAtIndex(sources, i);
        NSString* sourceName = CFBridgingRelease(ABRecordCopyValue(source, kABSourceNameProperty));
        NSString* sourceType = CFBridgingRelease(ABRecordCopyValue(source, kABSourceTypeProperty));
        NSLog(@"  source:%@, type: %@", sourceName, sourceType);
    }
    CFRelease(sources);
    
    CFArrayRef records = ABAddressBookCopyArrayOfAllPeople(addressBook);
    for (CFIndex i = 0; i < CFArrayGetCount(records); i++)
    {
        NSMutableSet *contactSet = [NSMutableSet set];
        
        ABRecordRef record = CFArrayGetValueAtIndex(records, i);
        [contactSet addObject:(__bridge id)record];
        
        NSArray *linkedRecordsArray = (__bridge NSArray *)ABPersonCopyArrayOfAllLinkedPeople(record);
        [contactSet addObjectsFromArray:linkedRecordsArray];
        
        // Your own custom "unified record" class (or just an NSSet!)
        NSSet *unifiedRecord = [[NSSet alloc] initWithSet:contactSet];
        
        [unifiedRecordsSet addObject:unifiedRecord];
        CFRelease(record);
    }
    
    CFRelease(records);
    
    return [unifiedRecordsSet allObjects];
}

- (NSSet *) getUnifiedAddressBookRecordFor: (ABRecordRef) record {
    NSMutableSet *contactSet = [NSMutableSet set];
    
    [contactSet addObject:(__bridge id)record];
    
    NSArray *linkedRecordsArray = (__bridge NSArray *)ABPersonCopyArrayOfAllLinkedPeople(record);
    [contactSet addObjectsFromArray:linkedRecordsArray];
    
    // Your own custom "unified record" class (or just an NSSet!)
    return [[NSSet alloc] initWithSet:contactSet];
}

- (void)pickPeopleInAddressBook:(ABAddressBookRef)addressBook
{
//	NSInteger numberOfPeople = ABAddressBookGetPersonCount(addressBook);
	NSInteger numberOfPeople = 5;

	NSArray *allPeople = CFBridgingRelease(ABAddressBookCopyArrayOfAllPeople(addressBook));
    
    allPeople = [self getUnifiedAddressBookRecords:addressBook];
    
	for (NSInteger i = 0; i < numberOfPeople; i++) {
        NSSet *unifiedRecord = allPeople[i];
        NonMOPerson *person = [[NonMOPerson alloc] init];
        
        NSEnumerator *enumerator = [unifiedRecord objectEnumerator];
        
        id value;
        
        while ((value = [enumerator nextObject])) {
            ABRecordRef rawPerson = (__bridge ABRecordRef) value;
            
            // Check for contact picture
            if (rawPerson != nil && ABPersonHasImageData(rawPerson)) {
                if ( &ABPersonCopyImageDataWithFormat != nil ) {
                    person.profileImage = [UIImage imageWithData:(__bridge NSData *)ABPersonCopyImageDataWithFormat(rawPerson, kABPersonImageFormatOriginalSize)];
                }
            }
            
            person.firstName = CFBridgingRelease(ABRecordCopyValue(rawPerson, kABPersonFirstNameProperty));
            person.lastName  = CFBridgingRelease(ABRecordCopyValue(rawPerson, kABPersonLastNameProperty));
            
            // TODO:  this needs to be mobile or iphone first the other because it is used for texting from the device

			ABMultiValueRef phoneNumbers = ABRecordCopyValue(rawPerson, kABPersonPhoneProperty);

			CFIndex numberOfPhoneNumbers = ABMultiValueGetCount(phoneNumbers);
			for (CFIndex i = 0; i < numberOfPhoneNumbers; i++) {
				NSString *phoneNumber = CFBridgingRelease(ABMultiValueCopyValueAtIndex(phoneNumbers, i));
				person.phoneNumber = phoneNumber;
				NSLog(@"  phone:%@", phoneNumber);
			}

			CFRelease(phoneNumbers);
        }
        
        // filter out contacts without names
        if (!(person.firstName == nil && person.lastName == nil)) {
            [self.ceaselessPeople addObject: person];
            NSLog(@"Name:%@ %@", person.firstName, person.lastName);
        } else {
            ++numberOfPeople; // need to loop through one more person
        }
	}
}

- (NSArray *) getAllCeaselessContacts {
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"Person"];
    fetchRequest.resultType = NSCountResultType;
    NSError *error;
    NSArray *persons = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    if(persons == nil) {
        NSLog(@"Fetch error: %@", error);
    }
    return persons;
}

- (void) refreshContactsFromAddressBook: (ABAddressBookRef)addressBook {
    
    NSArray * allAddressBookContacts = [self getUnifiedAddressBookRecords:addressBook];
    NSArray * allCeaselessContacts = [self getAllCeaselessContacts];
    
    // TODO what happens if someone links two contacts that were not linked before?
    // TODO what happens if someone unlinks two contacts that were linked before?
    
    // for each unified entry in the address book
    for(NSSet *unifiedRecord in allAddressBookContacts) {
        BOOL abcNotInCc = true;
        
        // if we do not have it in our Person model
        for(Person* person in allCeaselessContacts) {
            if ([self addressBookContactEqualsToCeaselessContactByFields:unifiedRecord forCeaselessContact:person]) {
                abcNotInCc = false;
                break;
            }
            // TODO do we need to check based on ID as well?
        }
        
        if(abcNotInCc) {
            [self addContactToCeaseless:unifiedRecord];
        }
    }
    
    // for each Person model
    for(Person* person in allCeaselessContacts) {
        BOOL ccInAbcById = false;
        BOOL ccInAbcByFields = false;
        NSSet* addressBookContact;
        // if we do not have it in our address book (based on fields)
        for(NSSet *unifiedRecord in allAddressBookContacts) {
            if([self addressBookContactEqualsToCeaselessContactByFields:unifiedRecord forCeaselessContact:person]){
                ccInAbcByFields = true;
                addressBookContact = unifiedRecord;
            }
            
            if([self addressBookContactEqualsToCeaselessContactByLocalId:unifiedRecord forCeaselessContact:person]) {
                ccInAbcById = true;
            }
        }
        
        if(ccInAbcByFields) {
            if(!ccInAbcById) {
                // update fields if we have it by id even though we don't have it by fields
                [self updateCeaselessContact:person withAddressBookContact: addressBookContact];
            }
        } else {
            if(ccInAbcById) {
                // if we do not have an id match or field match
                [self removeContactFromCeaseless:person];
            }
        }
    }
}

// compare the first name, last name, phone numbers, emails
- (BOOL) addressBookContactEqualsToCeaselessContactByFields: (NSSet *) addressBookContact forCeaselessContact: (Person *) ceaselessContact {

    // for each raw contact in the set
    NSEnumerator *enumerator = [addressBookContact objectEnumerator];
    id value;
    while ((value = [enumerator nextObject])) {
        ABRecordRef rawPerson = (__bridge ABRecordRef) value;
        BOOL firstNameMatch = [ceaselessContact.firstNames containsObject: CFBridgingRelease(ABRecordCopyValue(rawPerson, kABPersonFirstNameProperty))];
        BOOL lastNameMatch = [ceaselessContact.lastNames containsObject: CFBridgingRelease(ABRecordCopyValue(rawPerson, kABPersonLastNameProperty))];
        
        BOOL phoneNumberMatch = NO;
        ABMultiValueRef phoneNumbers = ABRecordCopyValue(rawPerson, kABPersonPhoneProperty);
        
        CFIndex numberOfPhoneNumbers = ABMultiValueGetCount(phoneNumbers);
        for (CFIndex i = 0; i < numberOfPhoneNumbers; i++) {
            NSString *phoneNumber = CFBridgingRelease(ABMultiValueCopyValueAtIndex(phoneNumbers, i));
            NSLog(@"  phone:%@", phoneNumber);
            if([ceaselessContact.phoneNumbers containsObject: phoneNumber]) {
                phoneNumberMatch = YES;
                break;
            }
        }
        
        CFRelease(phoneNumbers);

        BOOL emailMatch = NO;
        ABMultiValueRef emails = ABRecordCopyValue(rawPerson, kABPersonEmailProperty);
        
        CFIndex numberOfEmails = ABMultiValueGetCount(emails);
        for (CFIndex i = 0; i < numberOfEmails; i++) {
            NSString *email = CFBridgingRelease(ABMultiValueCopyValueAtIndex(emails, i));
            NSLog(@"  email:%@", email);
            if([ceaselessContact.emails containsObject: email]) {
                emailMatch = YES;
                break;
            }
        }
        
        CFRelease(emails);
        
        if (firstNameMatch && lastNameMatch && (phoneNumberMatch || emailMatch)) {
            return YES;
        }
    }
    return NO;
}

- (BOOL) addressBookContactEqualsToCeaselessContactByLocalId: (NSSet *) addressBookContact forCeaselessContact: (Person *) ceaselessContact {
    // for each raw contact in the set
    NSEnumerator *enumerator = [addressBookContact objectEnumerator];
    id value;
    BOOL localRecordIdMatch = NO;
    while ((value = [enumerator nextObject])) {
        ABRecordRef rawPerson = (__bridge ABRecordRef) value;
        if([ceaselessContact.addressBookId isEqual: @(ABRecordGetRecordID(rawPerson)).stringValue]) {
            localRecordIdMatch = YES;
            break;
        };
    }
    return localRecordIdMatch;
}

- (void) addContactToCeaseless: (NSSet *) addressBookContact {
    Person *newPerson = [NSEntityDescription insertNewObjectForEntityForName:@"Person" inManagedObjectContext:self.managedObjectContext];
    
    ABRecordRef rawPerson = (__bridge ABRecordRef) [addressBookContact anyObject];
    
    NSUUID  *UUID = [NSUUID UUID];
    newPerson.ceaselessId = [UUID UUIDString];
    newPerson.addressBookId = @(ABRecordGetRecordID(rawPerson)).stringValue;
    
    // for each raw contact in the set
    NSEnumerator *enumerator = [addressBookContact objectEnumerator];
    id value;
    NSMutableSet *phoneNumbers = [[NSMutableSet alloc] init];
    NSMutableSet *emails = [[NSMutableSet alloc] init];
    while ((value = [enumerator nextObject])) {
        ABRecordRef rawPerson = (__bridge ABRecordRef) value;
        
        // add phoneNumbers
        ABMultiValueRef rawPhoneNumbers = ABRecordCopyValue(rawPerson, kABPersonPhoneProperty);
        CFIndex numberOfPhoneNumbers = ABMultiValueGetCount(rawPhoneNumbers);
        for (CFIndex i = 0; i < numberOfPhoneNumbers; i++) {
            NSString *phoneNumber = CFBridgingRelease(ABMultiValueCopyValueAtIndex(rawPhoneNumbers, i));
            [phoneNumbers addObject:phoneNumber];
        }
        CFRelease(rawPhoneNumbers);
        
        // add emails
        ABMultiValueRef rawEmails = ABRecordCopyValue(rawPerson, kABPersonEmailProperty);
        CFIndex numberOfEmails = ABMultiValueGetCount(rawEmails);
        for (CFIndex i = 0; i < numberOfEmails; i++) {
            NSString *email = CFBridgingRelease(ABMultiValueCopyValueAtIndex(rawEmails, i));
            [emails addObject:email];
        }
        CFRelease(rawEmails);
    }
    
    [newPerson addPhoneNumbers: phoneNumbers];
    [newPerson addEmails: emails];
    
    // TODO need a method to refresh contact's phone numbers and e-mails when they change.
    NSError * error = nil;
    if (![self.managedObjectContext save: &error]) {
        NSLog(@"%s: Problem saving: %@", __PRETTY_FUNCTION__, error);
    }
}

- (void) removeContactFromCeaseless: (Person*) ceaselessContact {
    NSError * error = nil;
    [self.managedObjectContext deleteObject: ceaselessContact];

    if (![self.managedObjectContext save:&error]) {
        NSLog(@"%s: Problem saving: %@", __PRETTY_FUNCTION__, error);
    }
    
}

- (void) updateCeaselessContact: (Person*) ceaselessContact withAddressBookContact: (NSSet*) addressBookContact {
    ABRecordRef rawPerson = (__bridge ABRecordRef) [addressBookContact anyObject];
    
    ceaselessContact.firstNames = @[CFBridgingRelease(ABRecordCopyValue(rawPerson, kABPersonFirstNameProperty))];
    ceaselessContact.lastNames = @[CFBridgingRelease(ABRecordCopyValue(rawPerson, kABPersonLastNameProperty))];
    ceaselessContact.addressBookId = @(ABRecordGetRecordID(rawPerson)).stringValue;
    
    // for each raw contact in the set
    NSEnumerator *enumerator = [addressBookContact objectEnumerator];
    id value;
    NSMutableSet *phoneNumbers = [[NSMutableSet alloc] init];
    NSMutableSet *emails = [[NSMutableSet alloc] init];
    while ((value = [enumerator nextObject])) {
        ABRecordRef rawPerson = (__bridge ABRecordRef) value;
        
        // add phoneNumbers
        ABMultiValueRef rawPhoneNumbers = ABRecordCopyValue(rawPerson, kABPersonPhoneProperty);
        phoneNumbers = [self convertABMultiValueStringRefToSet:rawPhoneNumbers];
        CFRelease(rawPhoneNumbers);
        
        // add emails
        ABMultiValueRef rawEmails = ABRecordCopyValue(rawPerson, kABPersonEmailProperty);
        emails = [self convertABMultiValueStringRefToSet:rawEmails];
        CFRelease(rawEmails);
    }

    // update emails completely
    ceaselessContact.phoneNumbers = phoneNumbers;
    ceaselessContact.emails = emails;
    
    NSError * error = nil;
    if (![self.managedObjectContext save: &error]) {
        NSLog(@"%s: Problem saving: %@", __PRETTY_FUNCTION__, error);
    }
}

- (NSMutableSet *) convertABMultiValueStringRefToSet: (ABMultiValueRef) multiValue {
    NSMutableSet *result = [[NSMutableSet alloc] init];
    CFIndex numberOfValues = ABMultiValueGetCount(multiValue);
    for (CFIndex i = 0; i < numberOfValues; i++) {
        NSString *value = CFBridgingRelease(ABMultiValueCopyValueAtIndex(multiValue, i));
        [result addObject:value];
    }
    return result;
}

- (Person *) getCeaselessContactFromABRecord: (ABRecordRef) rawPerson {
    CeaselessLocalContacts *cc = [[CeaselessLocalContacts alloc]init];
    NSString *addressBookId = @(ABRecordGetRecordID(rawPerson)).stringValue;
    NSString *firstName = CFBridgingRelease(ABRecordCopyValue(rawPerson, kABPersonFirstNameProperty));
    NSString *lastName = CFBridgingRelease(ABRecordCopyValue(rawPerson, kABPersonLastNameProperty));
    ABMultiValueRef rawPhoneNumbers = ABRecordCopyValue(rawPerson, kABPersonPhoneProperty);
    ABMultiValueRef rawEmails = ABRecordCopyValue(rawPerson, kABPersonEmailProperty);
    NSSet * phoneNumbers = [self convertABMultiValueStringRefToSet:rawPhoneNumbers];
    NSSet * emails = [self convertABMultiValueStringRefToSet:rawEmails];
    
    NSUUID *oNSUUID = [[UIDevice currentDevice] identifierForVendor];
    NSString *deviceId = [oNSUUID UUIDString];
    
    CFRelease(rawPhoneNumbers);
    CFRelease(rawEmails);
    

    NSArray *byName = [cc lookupContactsByFirstName:firstName andLastName:lastName];
    NSUInteger resultSize = [byName count];
    if (resultSize > 1) {
        NSArray *resultsFilteredByPhoneOrEmail = [cc filterResults:byName byEmails:emails orPhoneNumbers:phoneNumbers];
        NSUInteger filteredResultSize = [resultsFilteredByPhoneOrEmail count];
        if (filteredResultSize > 1) {
            // throw an exception
        } else if (filteredResultSize == 1) {
            return resultsFilteredByPhoneOrEmail[0];
        } else {
            // so we found multiple contacts by name but could not disambiguate them by email or phone
            // throw an exception
        }
    } else if (resultSize == 1) {
        return byName[0];
    } else {
        NSArray *resultsByDeviceAndAddressBookId = [cc lookupContactsByDeviceId:deviceId andAddressBookId: addressBookId];
        NSUInteger byLocalIdResultSize = [resultsByDeviceAndAddressBookId count];
        if (byLocalIdResultSize > 1) {
            // throw an exception. Ceaseless messed up in creating multiple contacts for the same record id
        } else if(byLocalIdResultSize == 1) {
            return resultsByDeviceAndAddressBookId[0];
        } else {
            return nil; // we really found nothing in this case
        }
    }
    return nil; //
}

- (Person *) createCeaselessContactFromABRecord: (ABRecordRef) rawPerson {
    Person *newCeaselessPerson = [NSEntityDescription insertNewObjectForEntityForName:@"Person" inManagedObjectContext:self.managedObjectContext];
    [self buildCeaselessContact:newCeaselessPerson fromABRecord:rawPerson];
    NSUUID  *UUID = [NSUUID UUID];
    newCeaselessPerson.ceaselessId = [UUID UUIDString];
    // save the updated ceaseless contact
    return newCeaselessPerson;
}

- (void) updateCeaselessContactFromABRecord: (ABRecordRef) rawPerson {
    NSSet *unifiedRecord = [self getUnifiedAddressBookRecordFor:rawPerson];
    NSMutableArray *matchingCeaselessContacts = @[];
    NSUInteger resultSize = [matchingCeaselessContacts count];
    if (resultSize == 1) {
        Person *ceaselessContact = matchingCeaselessContacts[0];
        [self buildCeaselessContact:ceaselessContact fromABRecord:rawPerson];
        // save the updated ceaseless contact
    } else if(resultSize > 1) {
        // when we get mutliple, keep the first
        Person *personToKeep = [matchingCeaselessContacts objectAtIndex:0];
        [matchingCeaselessContacts removeObjectAtIndex: 0];
        for(Person *personToRemove in matchingCeaselessContacts) {
            [self copyDataFromCeaselessContact: personToRemove toContact: personToKeep];
            // delete the personToRemove
        }
        // save the personToKeep
    } else {
            // either create it or do nothing
    }
}

- (void) buildCeaselessContact:(Person*) ceaselessContact fromABRecord: (ABRecordRef) rawPerson {
    NSSet *unifiedRecord = [self getUnifiedAddressBookRecordFor:rawPerson];
    ceaselessContact.firstNames = @[];
    ceaselessContact.lastNames = @[];
    ceaselessContact.emails = @[];
    ceaselessContact.phoneNumbers = @[];
    ceaselessContact.addressBookId = @[];
}

- (void) copyDataFromCeaselessContact: (Person *) src toContact: (Person *) dst {
    // for each relationship, change the id of the relationship to point to the id of the one we want to keep
}

@end
