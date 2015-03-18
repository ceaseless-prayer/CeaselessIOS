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
#import "PrayerRecord.h"

@interface PersonPicker ()

@property (strong, nonatomic) NSMutableArray *ceaselessPeople;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) CeaselessLocalContacts *ceaselessContacts;

@end

@implementation PersonPicker

- (instancetype) init {
    self = [super init];
    if (self) {
        AppDelegate *appDelegate = (id) [[UIApplication sharedApplication] delegate];
        self.managedObjectContext = appDelegate.managedObjectContext;
        self.ceaselessContacts = [[CeaselessLocalContacts alloc]init];
        _ceaselessContacts.contacts = [[NSMutableArray alloc] initWithArray:[self getAllCeaselessContacts]];
        _ceaselessContacts.names = [[NSMutableArray alloc] initWithArray:[self getAllNames]];
        _ceaselessContacts.addressBookIds = [[NSMutableArray alloc] initWithArray:[self getAllAddressBookIds]];
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
        [self refreshCeaselessContactsFromAddressBook:addressBook];
		if (addressBook) CFRelease(addressBook);
	}
	if ([self.ceaselessPeople count] > 0) {
		AppDelegate *appDelegate = (id) [[UIApplication sharedApplication] delegate];
		appDelegate.peopleArray = self.ceaselessPeople;

	}
}

- (void)pickPerson:(ABRecordRef)rawPerson personToShow:(Person *)personToShow {
    NSSet *unifiedRecord = [self getUnifiedAddressBookRecordFor:rawPerson];
    NonMOPerson *person = [[NonMOPerson alloc] init];
    person.person = personToShow;
    
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
    
    [self.ceaselessPeople addObject: person];
    [self createPrayerRecordForPerson: personToShow];
    NSLog(@"Name:%@ %@", person.firstName, person.lastName);
}

- (void)pickPeopleInAddressBook:(ABAddressBookRef)addressBook
{
    
    NSInteger numberOfPeople = 5;
    NSSortDescriptor *descriptor = [NSSortDescriptor sortDescriptorWithKey:@"prayerRecords.@count" ascending:YES];
    NSArray *ceaselessPeople = [[self getAllCeaselessContacts] sortedArrayUsingDescriptors:[NSArray arrayWithObject:descriptor]];
    if ([ceaselessPeople count] < numberOfPeople) {
        numberOfPeople = [ceaselessPeople count];
    }
    
    for (NSInteger i = 0; i< numberOfPeople; i++) {
        Person *personToShow = ceaselessPeople[i];
        
        ABRecordRef rawPerson = NULL;
        BOOL personPicked = NO;
        
        for(AddressBookId *abId in personToShow.addressBookIds) { // try address book records until you have a valid one.
            rawPerson = ABAddressBookGetPersonWithRecordID(addressBook, (ABRecordID) [abId.recordId intValue]);
            if (rawPerson != NULL) { // we got one that points to a record
                // check if the record matches our original person contact, since it could be something else entirely
                Person *validatedPerson = [self getCeaselessContactFromABRecord:rawPerson];
                if(validatedPerson == personToShow) {
                    // since it matches, we can pick this person
                    [self pickPerson: rawPerson personToShow: personToShow];
                    personPicked = YES;
                    break;
                }
                // we gotta pick something else if it doesn't match
                // let background refresh processes solve the consistency issues.
            }
        }
        
        if(!personPicked) {
            NSLog(@"Could not pick %@", personToShow);
            // we gotta loop through again if we haven't picked someone yet.
            if (numberOfPeople < [ceaselessPeople count]) {
                ++numberOfPeople;
            }
        }
    }
}


- (void) refreshCeaselessContactsFromAddressBook: (ABAddressBookRef)addressBook {
    NSArray * allAddressBookContacts = [self getUnifiedAddressBookRecords:addressBook];
    
    NSLog(@"Total Ceaseless contacts: %lu", (unsigned long)[_ceaselessContacts.contacts count]);
    for (NSSet *unifiedRecord in allAddressBookContacts) {
        [self updateCeaselessContactFromABRecord:(__bridge ABRecordRef)[unifiedRecord anyObject]];
    }
    
    NSArray *allCeaselessContacts = [self getAllCeaselessContacts];
    for (Person *person in allCeaselessContacts) {
        [self updateCeaselessContactLocalIds: person fromAddressBook: addressBook];
    }
}

- (void) updateCeaselessContactLocalIds: (Person *) person fromAddressBook: (ABAddressBookRef) addressBook {
    ABRecordRef rawPerson = NULL;
    for (AddressBookId *abId in person.addressBookIds) {
        rawPerson = ABAddressBookGetPersonWithRecordID(addressBook, (ABRecordID) [abId.recordId intValue]);
        if (rawPerson != NULL) { // we got one that points to a record
            // check if the record matches our original person contact, since it could be something else entirely
            Person *validatedPerson = [self getCeaselessContactFromABRecord:rawPerson];
            if(validatedPerson != person) {
                // we are pointing to a record that is not pointing back to us
                // prune it from our list of local ids.
                NSMutableSet *addressBookIds = [[NSMutableSet alloc] initWithSet:person.addressBookIds];
                [addressBookIds removeObject:abId];
                person.addressBookIds = addressBookIds;
            }
        } else {
            // we are pointing to a record that is not pointing back to us
            // prune it from our list of local ids.
            NSMutableSet *addressBookIds = [[NSMutableSet alloc] initWithSet:person.addressBookIds];
            [addressBookIds removeObject:abId];
            person.addressBookIds = addressBookIds;
        }
    }
    
    // save
    NSError *error;
    if (![self.managedObjectContext save:&error]) {
        NSLog(@"%s: Problem saving: %@", __PRETTY_FUNCTION__, error);
    }
}

- (NSArray *)getUnifiedAddressBookRecords:(ABAddressBookRef)addressBook
{
    // http://stackoverflow.com/questions/11351454/dealing-with-duplicate-contacts-due-to-linked-cards-in-ios-address-book-api
    NSMutableSet *unifiedRecordsSet = [NSMutableSet set];
    
    // TODO remove this block of code.
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

- (NSArray *) getAllCeaselessContacts {
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Person"
                                              inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    NSError * error = nil;
    NSArray *persons = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    
    if(persons == nil) {
        NSLog(@"Fetch error: %@", error);
    }
    return persons;
}

- (NSArray *) getAllNames {
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Name"
                                              inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    NSError * error = nil;
    NSArray *names = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    
    if(names == nil) {
        NSLog(@"Fetch error: %@", error);
    }
    return names;
}

- (NSArray *) getAllAddressBookIds {
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"AddressBookId"
                                              inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    NSError * error = nil;
    NSArray *ids = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    
    if(ids == nil) {
        NSLog(@"Fetch error: %@", error);
    }
    return ids;
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
    
    // first look up by id
    NSString *addressBookId = @(ABRecordGetRecordID(rawPerson)).stringValue;
    NSArray *resultsByDeviceAndAddressBookId = [_ceaselessContacts lookupContactsByAddressBookId: addressBookId];
    NSUInteger byLocalIdResultSize = [resultsByDeviceAndAddressBookId count];
    
    if (byLocalIdResultSize == 1) {
        // we found an exact match, this is the right one.
        return resultsByDeviceAndAddressBookId[0];
    } else if (byLocalIdResultSize > 1) {
        // throw an exception. Ceaseless messed up in creating multiple contacts for the same record id
        NSLog(@"This should not happen, we shouldn't get multiple results for a local id %@", addressBookId);
        return nil;
    }
    
    // if id lookup fails, then look up by names, emails and phone numbers.
    NSString *firstName = CFBridgingRelease(ABRecordCopyValue(rawPerson, kABPersonFirstNameProperty));
    NSString *lastName = CFBridgingRelease(ABRecordCopyValue(rawPerson, kABPersonLastNameProperty));
    ABMultiValueRef rawPhoneNumbers = ABRecordCopyValue(rawPerson, kABPersonPhoneProperty);
    ABMultiValueRef rawEmails = ABRecordCopyValue(rawPerson, kABPersonEmailProperty);
    NSSet *phoneNumbers = [self convertABMultiValueStringRefToSet:rawPhoneNumbers];
    NSSet *emails = [self convertABMultiValueStringRefToSet:rawEmails];
    NSSet *unifiedRecord = [self getUnifiedAddressBookRecordFor:rawPerson];
    
    CFRelease(rawPhoneNumbers);
    CFRelease(rawEmails);

    NSArray *resultsByName = [_ceaselessContacts lookupContactsByFirstName:firstName andLastName:lastName];
    NSUInteger resultSize = [resultsByName count];
    
    // Note: We chose to let users handle cases of contacts that are unlinked, but
    // are actually the same. Although these cases may show up multiple times in Ceaseless
    // we let users decide what to do by either:
    // linking the contacts or ignoring a contact from their prayer list.
    
    if ([phoneNumbers count] == 0  && [emails count] == 0
        && [unifiedRecord count] == 1 && resultSize == 1) {
        // we are dealing with a record that has no phone number or email.
        // we can only treat it as a Ceaseless contact if it has no other
        // contacts that match its name and has no linked contacts.
        return resultsByName[0];
    }
    
    NSArray *resultsFilteredByPhoneOrEmail = [_ceaselessContacts filterResults:resultsByName byEmails:emails orPhoneNumbers:phoneNumbers];
    NSUInteger filteredResultSize = [resultsFilteredByPhoneOrEmail count];
    
    if (filteredResultSize == 0) {
        // There is no Ceaseless contact which shares first name, last name and email/phone number with this record.
        return nil; // we really found nothing in this case
    }
    
    if (filteredResultSize == 1) {
        // we found exactly one match, return it
        return resultsFilteredByPhoneOrEmail[0];
    }
    
    if(filteredResultSize > 1) {
        // we could not disambiguate multiple Ceaseless contacts
        // by their first name, last name, email or phone.
        // we need to throw an exception.
        NSLog(@"This should not happen, we can do nothing when we have more than 1 result");
        return nil;
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
    [self.ceaselessContacts.contacts addObject:newCeaselessPerson];
    return newCeaselessPerson;
}

- (PrayerRecord *) createPrayerRecordForPerson: (Person*) person {
    PrayerRecord *prayerRecord = [NSEntityDescription insertNewObjectForEntityForName:@"PrayerRecord" inManagedObjectContext:self.managedObjectContext];
    prayerRecord.person = person;
    prayerRecord.createDate = [NSDate date];
    prayerRecord.type = kPrayerRecordTypePersonSuggested;

    // save our changes
    NSError *error;
    if (![self.managedObjectContext save:&error]) {
        NSLog(@"%s: Problem saving: %@", __PRETTY_FUNCTION__, error);
    }
    return prayerRecord;
}

- (void) updateCeaselessContactFromABRecord: (ABRecordRef) rawPerson {
    NSMutableSet *matchingCeaselessContacts = [[NSMutableSet alloc]init];
    NSSet *unifiedRecord = [self getUnifiedAddressBookRecordFor:rawPerson];
    BOOL hasFirstName = NO;
    for(id record in unifiedRecord) {
        ABRecordRef personData = (__bridge ABRecordRef) record;
        NSString *firstName = CFBridgingRelease(ABRecordCopyValue(rawPerson, kABPersonFirstNameProperty));
        if (firstName != nil) {
            hasFirstName = YES;
        }
        Person *ceaselessContact = [self getCeaselessContactFromABRecord:personData];
        if(ceaselessContact != nil) {
            [matchingCeaselessContacts addObject: ceaselessContact];
        }
    }
    NSUInteger resultSize = [matchingCeaselessContacts count];

    if (hasFirstName) { // only operate on records with a first name
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
            [self createCeaselessContactFromABRecord:rawPerson];
        }
        
        // save our changes
        NSError *error;
        if (![self.managedObjectContext save:&error]) {
            NSLog(@"%s: Problem saving: %@", __PRETTY_FUNCTION__, error);
        }
    }
}

- (void) buildCeaselessContact:(Person*) ceaselessContact fromABRecord: (ABRecordRef) rawPerson {
    NSSet *unifiedRecord = [self getUnifiedAddressBookRecordFor:rawPerson];
    ceaselessContact.firstNames = [self buildFirstNames:unifiedRecord];
    ceaselessContact.lastNames = [self buildLastNames:unifiedRecord];
    ceaselessContact.addressBookIds = [self buildAddressBookIds:unifiedRecord];
    ceaselessContact.phoneNumbers = [self buildPhoneNumbers:unifiedRecord];
    ceaselessContact.emails = [self buildEmails:unifiedRecord];
}

- (NSMutableSet *)buildFirstNames:(NSSet *)unifiedRecord {
    NSMutableSet *firstNames = [[NSMutableSet alloc]init];
    for (id record in unifiedRecord) {
        ABRecordRef personData = (__bridge ABRecordRef) record;
        NSString *firstName = CFBridgingRelease(ABRecordCopyValue(personData, kABPersonFirstNameProperty));
        NSPredicate *predicate = [NSPredicate predicateWithFormat:
                                  @"name = %@", firstName];
        if(firstName != nil && ![firstName isEqual: @""]) {
            Name *name = (Name *) [self getOrCreateManagedObject:@"Name" withPredicate:predicate];
            name.name = firstName;
            [firstNames addObject: name];
        }
    }
    return firstNames;
}

- (NSMutableSet *)buildLastNames:(NSSet *)unifiedRecord {
    NSMutableSet *lastNames = [[NSMutableSet alloc]init];
    for (id record in unifiedRecord) {
        ABRecordRef personData = (__bridge ABRecordRef) record;
        NSString *lastName = CFBridgingRelease(ABRecordCopyValue(personData, kABPersonLastNameProperty));
        NSPredicate *predicate = [NSPredicate predicateWithFormat:
                                  @"name = %@", lastName];
        if(lastName != nil && ![lastName isEqual: @""]) {
            Name *name = (Name *) [self getOrCreateManagedObject:@"Name" withPredicate:predicate];
            name.name = lastName;
            [lastNames addObject: name];
        }
    }
    return lastNames;
}

- (NSMutableSet*)buildAddressBookIds:(NSSet *)unifiedRecord {
    
    NSUUID *oNSUUID = [[UIDevice currentDevice] identifierForVendor];
    NSString *deviceId = [oNSUUID UUIDString];
    NSMutableSet *addressBookIds = [[NSMutableSet alloc]init];
    
    for (id record in unifiedRecord) {
        ABRecordRef personData = (__bridge ABRecordRef) record;
        NSString * addressBookId = @(ABRecordGetRecordID(personData)).stringValue;
        NSPredicate *predicate = [NSPredicate predicateWithFormat:
                                  @"recordId = %@ AND deviceId = %@", addressBookId, deviceId];
        AddressBookId *abId = (AddressBookId *) [self getOrCreateManagedObject:@"AddressBookId" withPredicate:predicate];
        abId.recordId = addressBookId;
        abId.deviceId = deviceId;
        [addressBookIds addObject: abId];
    }
    return addressBookIds;
}

- (NSMutableSet *)buildPhoneNumbers:(NSSet *)unifiedRecord {
    NSMutableSet *phoneNumbers = [[NSMutableSet alloc]init];
    NSMutableSet *rawPhoneNumbers = [self collectMultiValueRefAcrossSetMembers:unifiedRecord propertyKey:kABPersonPhoneProperty];
    for (NSString *phoneNumber in rawPhoneNumbers) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:
                                  @"number = %@", phoneNumber];
        PhoneNumber *phoneNumberObject = (PhoneNumber *) [self getOrCreateManagedObject: @"PhoneNumber" withPredicate:predicate];
        phoneNumberObject.number = phoneNumber;
        [phoneNumbers addObject: phoneNumberObject];
    }
    return phoneNumbers;
}

- (NSMutableSet *)buildEmails:(NSSet *)unifiedRecord {
    NSMutableSet *emails = [[NSMutableSet alloc]init];
    NSMutableSet *rawEmails = [self collectMultiValueRefAcrossSetMembers:unifiedRecord propertyKey:kABPersonEmailProperty];
    for (NSString *email in rawEmails) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:
                                  @"address = %@", email];
        Email *emailObject = (Email *) [self getOrCreateManagedObject: @"Email" withPredicate:predicate];
        emailObject.address = email;
        [emails addObject: emailObject];
    }
    return emails;
}

- (NSManagedObject*) getOrCreateManagedObject:(NSString *)entityName withPredicate: (NSPredicate*)predicate {
    NSManagedObject *result;
    NSManagedObjectContext *context = [self managedObjectContext];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:entityName inManagedObjectContext:context];
    [request setEntity:entity];
    [request setPredicate:predicate];
    NSError *errorFetch = nil;
    NSArray *existingResults = [context executeFetchRequest:request error:&errorFetch];
    if([existingResults count] < 1) {
        result = [NSEntityDescription insertNewObjectForEntityForName:entityName inManagedObjectContext:self.managedObjectContext];
        // HACK I don't want to have to check just for name specifically here.
        // for now we need to add it to the cached array of names if it is new.
        if([entityName isEqual: @"Name"]) {
            [self.ceaselessContacts.names addObject: result];
        } else if([entityName isEqual: @"AddressBookId"]) {
            [self.ceaselessContacts.addressBookIds addObject: result];
        }
    } else {
        result = existingResults[0];
    }
    return result;
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

- (NSMutableSet*) collectMultiValueRefAcrossSetMembers: (NSSet *)unifiedRecord propertyKey: (ABPropertyID) property {
    
    NSMutableSet *resultSet = [[NSMutableSet alloc]init];
    for (id record in unifiedRecord) {
        ABRecordRef personData = (__bridge ABRecordRef) record;
        NSSet *recordValues = [self convertABMultiValueStringRefToSet:ABRecordCopyValue(personData, property)];
        [resultSet unionSet:recordValues];
    }
    return resultSet;
}

@end
