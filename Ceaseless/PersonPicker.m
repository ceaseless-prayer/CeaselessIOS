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
    NSSet *phoneNumbers = [self convertABMultiValueStringRefToSet:rawPhoneNumbers];
    NSSet *emails = [self convertABMultiValueStringRefToSet:rawEmails];
    
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
        NSArray *resultsByDeviceAndAddressBookId = [cc lookupContactsByAddressBookId: addressBookId];
        NSUInteger byLocalIdResultSize = [resultsByDeviceAndAddressBookId count];
        if (byLocalIdResultSize > 1) {
            // throw an exception. Ceaseless messed up in creating multiple contacts for the same record id
        } else if(byLocalIdResultSize == 1) {
            return resultsByDeviceAndAddressBookId[0];
        } else {
            return nil; // we really found nothing in this case
        }
    }
    return nil;
}

- (Person *) createCeaselessContactFromABRecord: (ABRecordRef) rawPerson {
    Person *newCeaselessPerson = [NSEntityDescription insertNewObjectForEntityForName:@"Person" inManagedObjectContext:self.managedObjectContext];
    [self buildCeaselessContact:newCeaselessPerson fromABRecord:rawPerson];
    NSUUID  *UUID = [NSUUID UUID];
    newCeaselessPerson.ceaselessId = [UUID UUIDString];
    // save our changes
    NSError *error;
    if (![self.managedObjectContext save:&error]) {
        NSLog(@"%s: Problem saving: %@", __PRETTY_FUNCTION__, error);
    }
    return newCeaselessPerson;
}

- (void) updateCeaselessContactFromABRecord: (ABRecordRef) rawPerson {
    NSMutableSet *matchingCeaselessContacts = [[NSMutableSet alloc]init];
    NSSet *unifiedRecord = [self getUnifiedAddressBookRecordFor:rawPerson];
    for(id record in unifiedRecord) {
        ABRecordRef personData = (__bridge ABRecordRef) record;
        [matchingCeaselessContacts addObject: [self getCeaselessContactFromABRecord:personData]];
    }
    NSUInteger resultSize = [matchingCeaselessContacts count];
   
    if (resultSize == 1) {
        Person *ceaselessContact = [matchingCeaselessContacts anyObject];
        [self buildCeaselessContact:ceaselessContact fromABRecord:rawPerson];
    } else if(resultSize > 1) {
        // when we get multiple, keep the first
        Person *personToKeep = [matchingCeaselessContacts anyObject];
        [matchingCeaselessContacts removeObject: personToKeep];
        // remove the rest
        for(Person *personToRemove in matchingCeaselessContacts) {
            [self copyDataFromCeaselessContact: personToRemove toContact: personToKeep];
            [self.managedObjectContext deleteObject: personToRemove];
        }
    } else {
            // either create it or do nothing
    }

    // save our changes
    NSError *error;
    if (![self.managedObjectContext save:&error]) {
        NSLog(@"%s: Problem saving: %@", __PRETTY_FUNCTION__, error);
    }
}

- (void) buildCeaselessContact:(Person*) ceaselessContact fromABRecord: (ABRecordRef) rawPerson {
    NSSet *unifiedRecord = [self getUnifiedAddressBookRecordFor:rawPerson];
    NSMutableSet *firstNames = [[NSMutableSet alloc]init];
    NSMutableSet *lastNames = [[NSMutableSet alloc]init];
    NSMutableSet *emails = [[NSMutableSet alloc]init];
    NSMutableSet *phoneNumbers = [[NSMutableSet alloc]init];
    NSMutableSet *addressBookIds = [[NSMutableSet alloc]init];
    NSUUID *oNSUUID = [[UIDevice currentDevice] identifierForVendor];
    NSString *deviceId = [oNSUUID UUIDString];
    
    for (id record in unifiedRecord) {
        ABRecordRef personData = (__bridge ABRecordRef) record;
        NSString *firstName = CFBridgingRelease(ABRecordCopyValue(personData, kABPersonFirstNameProperty));
        if(firstName != nil && ![firstName isEqual: @""]) {
            [firstNames addObject: firstName];
        }
    }
    ceaselessContact.firstNames = firstNames;
    
    for (id record in unifiedRecord) {
        ABRecordRef personData = (__bridge ABRecordRef) record;
        NSString *lastName = CFBridgingRelease(ABRecordCopyValue(personData, kABPersonLastNameProperty));
        if(lastName != nil && ![lastName isEqual: @""]) {
            [lastNames addObject: lastName];
        }
    }
    ceaselessContact.lastNames = lastNames;
    
    for (id record in unifiedRecord) {
        ABRecordRef personData = (__bridge ABRecordRef) record;
        NSString * addressBookId = @(ABRecordGetRecordID(personData)).stringValue;
        AddressBookId *abId = [NSEntityDescription insertNewObjectForEntityForName:@"AddressBookId" inManagedObjectContext:self.managedObjectContext];
        abId.recordId = addressBookId;
        abId.deviceId = deviceId;
        [addressBookIds addObject: abId];
    }
    ceaselessContact.addressBookIds = addressBookIds;
    
    for (id record in unifiedRecord) {
        ABRecordRef personData = (__bridge ABRecordRef) record;
        NSSet *recordPhoneNumbers = [self convertABMultiValueStringRefToSet:ABRecordCopyValue(personData, kABPersonPhoneProperty)];
        [phoneNumbers unionSet:recordPhoneNumbers];
        
        // TODO
//        PhoneNumber *phoneNumber = [NSEntityDescription insertNewObjectForEntityForName:@"PhoneNumber" inManagedObjectContext:self.managedObjectContext];
    }
    ceaselessContact.phoneNumbers = phoneNumbers;

    for (id record in unifiedRecord) {
        ABRecordRef personData = (__bridge ABRecordRef) record;
        NSSet *recordEmails = [self convertABMultiValueStringRefToSet:ABRecordCopyValue(personData, kABPersonEmailProperty)];
        [emails unionSet:recordEmails];
        
//        Email *email = [NSEntityDescription insertNewObjectForEntityForName:@"Email" inManagedObjectContext:self.managedObjectContext];
    }
    ceaselessContact.emails = emails;
}

- (void) copyDataFromCeaselessContact: (Person *) src toContact: (Person *) dst {
    // for each relationship, change the id of the relationship to point to the id of the one we want to keep
    [src addFirstNames:dst.firstNames];
    [src addLastNames:dst.lastNames];
    [src addPhoneNumbers:dst.phoneNumbers];
    [src addEmails:dst.emails];
    // TODO because notes and prayer records have a to-one relationship
    // do we need to remove the old relationship off the destination before this will work?
    // test it out.
    [src addNotes:dst.notes];
    [src addPrayerRecords:dst.prayerRecords];
}

@end
