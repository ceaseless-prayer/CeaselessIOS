//
//  CeaselessContacts.m
//  Ceaseless
//
//  Created by Christopher Lim on 3/13/15.
//  Copyright (c) 2015 Christopher Lim. All rights reserved.
//

#import "CeaselessLocalContacts.h"
#import "AppConstants.h"
#import "AppUtils.h"

@implementation CeaselessLocalContacts

+ (id) sharedCeaselessLocalContacts {
    static CeaselessLocalContacts *sharedCeaselessLocalContacts = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedCeaselessLocalContacts = [[self alloc] init];
        // listen for changes to address book and update.
        ABAddressBookRegisterExternalChangeCallback(sharedCeaselessLocalContacts.addressBook, externalAddressBookChangeCallback, (__bridge void *)(sharedCeaselessLocalContacts));
    });
    
    return sharedCeaselessLocalContacts;
}

- (instancetype) init {
    AppDelegate *appDelegate = (id) [[UIApplication sharedApplication] delegate];
    CFErrorRef error = NULL;
    ABAddressBookRef addressBook = [AppUtils getAddressBookRef];
    CFBridgingRelease(error);
    // TODO when is this address book cleaned up?
    return [self initWithManagedObjectContext:appDelegate.managedObjectContext andAddressBook:addressBook];
}

- (instancetype) initWithManagedObjectContext: (NSManagedObjectContext *) context andAddressBook:(ABAddressBookRef)addressBook {
    self = [super init];
    if (self) {
        self.internalAddressBookChange = NO;
        self.syncing = NO;
        self.backgroundTask = UIBackgroundTaskInvalid;
        self.addressBook = addressBook;
        self.managedObjectContext = context;
        _managedObjectContext = context;
    }
    return self;
}

- (NSArray *) filterResults: (NSArray*) results byEmails:(NSSet*) emails orPhoneNumbers: (NSSet*) phoneNumbers {
    NSMutableArray *filteredResults = [[NSMutableArray alloc]init];
    
    NSPredicate *getEmailObj = [NSPredicate predicateWithFormat:@"address IN %@", emails];
    NSPredicate *getPhoneNumberObj = [NSPredicate predicateWithFormat:@"number IN %@", phoneNumbers];
    
    for (PersonIdentifier *contact in results) {
        
        NSSet *matchingEmails = [contact.emails filteredSetUsingPredicate: getEmailObj];
        NSSet *matchingPhoneNumbers = [contact.phoneNumbers filteredSetUsingPredicate: getPhoneNumberObj];
        
        if([matchingEmails count] > 0 || [matchingPhoneNumbers count] > 0) {
            [filteredResults addObject:contact];
        }
    }
    
    return filteredResults;
}

- (NSArray *) lookupContactsByFirstName:(NSString*) firstName andLastName: (NSString*) lastName {
    NSArray *results = [[NSArray alloc]init];
    NSPredicate *getFirstNameObj = [NSPredicate predicateWithFormat:@"name = %@", firstName];
    NSPredicate *getLastNameObj = [NSPredicate predicateWithFormat:@"name = %@", lastName];
    
    NSArray* firstNameObj = [self fetchEntityForName:@"Name" withPredicate: getFirstNameObj];
    NSArray* lastNameObj = [self fetchEntityForName:@"Name" withPredicate: getLastNameObj];
    
    if([firstNameObj count] > 0 && [lastNameObj count] > 0) {
        NSPredicate *namePredicate = [NSPredicate predicateWithFormat: @"%@ IN firstNames AND %@ IN lastNames", firstNameObj[0], lastNameObj[0]];
        results = [self fetchEntityForName:@"PersonIdentifier" withPredicate:namePredicate];
    }
    
    return results;
}

- (NSArray *) lookupContactsByAddressBookId:(NSString*) addressBookId {
    NSArray *results = [[NSArray alloc] init];
    NSUUID *oNSUUID = [[UIDevice currentDevice] identifierForVendor];
    NSString *deviceId = [oNSUUID UUIDString];
    
    NSPredicate *getAddressBookIdObj = [NSPredicate predicateWithFormat:
                                        @"recordId = %@ AND deviceId = %@", addressBookId, deviceId];
    NSArray *addressBookIdObj = [self fetchEntityForName:@"AddressBookId" withPredicate: getAddressBookIdObj];
    if([addressBookIdObj count] > 0) {
        NSPredicate *idPredicate = [NSPredicate predicateWithFormat: @"%@ IN addressBookIds", addressBookIdObj[0]];
        results = [self fetchEntityForName:@"PersonIdentifier" withPredicate: idPredicate];
    }
    return results;
}

- (ABRecordRef) getRepresentativeABPersonForCeaselessContact: (PersonIdentifier*) person {
    return ABAddressBookGetPersonWithRecordID(_addressBook, (ABRecordID) [person.representativeInfo.primaryAddressBookId.recordId intValue]);
}

#pragma mark - Keeping Ceaseless and the address book in sync
void externalAddressBookChangeCallback (ABAddressBookRef addressBook, CFDictionaryRef info, void *context) {
    CeaselessLocalContacts *clc = (__bridge CeaselessLocalContacts *) context;
    // we need to use this timer because
    // the OS sends us multiple notifications when the address book changes
    // this way we can pretend that any notifications that come within 4 seconds of one another
    // are actually one notification
    // and that means when we set internalAddressBookChange = NO in the selector
    // it will only happen one time instead of going into the method again and
    // doing a sync when we don't want it to (since the address book change came from within the app itself)
    // http://stackoverflow.com/questions/10096480/abaddressbookregisterexternalchangecallback-called-several-times
    [clc.addressBookChangeNotificationTimer invalidate];
    clc.addressBookChangeNotificationTimer = nil;
    clc.addressBookChangeNotificationTimer = [NSTimer scheduledTimerWithTimeInterval:4.0
                                                        target:clc
                                                      selector:@selector(handleAddressBookChanges)
                                                      userInfo:nil
                                                       repeats:NO];
}

- (void) handleAddressBookChanges {
    if(self.internalAddressBookChange) {
        self.internalAddressBookChange = NO;
    } else {
        [self ensureCeaselessContactsSynced];
    }
}

- (void) ensureCeaselessContactsSynced {
    if(!_syncing && ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusAuthorized && self.backgroundTask == UIBackgroundTaskInvalid) {
        
        self.backgroundTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
            NSLog(@"Background handler called. Not running background tasks anymore.");
            [[UIApplication sharedApplication] endBackgroundTask:self.backgroundTask];
            self.backgroundTask = UIBackgroundTaskInvalid;
        }];
        
        NSDate *syncStart = [NSDate date];
        _syncing = YES;
        // refresh address book in the background
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            ABAddressBookRef addressBook2 = [AppUtils getAddressBookRef];
            
            NSManagedObjectContext *managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
            [managedObjectContext setParentContext:self.managedObjectContext];
            
            CeaselessLocalContacts *clc = [[CeaselessLocalContacts alloc] initWithManagedObjectContext:managedObjectContext andAddressBook: addressBook2];
            [clc.managedObjectContext performBlockAndWait: ^{
                [clc refreshCeaselessContacts];
            }];
            
            // ensure the context is fully saved.
            NSError *error;
            if (![self.managedObjectContext save:&error]) {
                NSLog(@"%s: Problem saving: %@", __PRETTY_FUNCTION__, error);
            }
            
            if (addressBook2) CFRelease(addressBook2);
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            NSDate *now = [NSDate date];
            [defaults setObject:now forKey:kLocalLastAddressBookSyncedDate];
            [defaults synchronize];

			dispatch_async(dispatch_get_main_queue(), ^(void) {
				[[NSNotificationCenter defaultCenter] postNotificationName:kContactsSyncedNotification object:nil];
			});
            
            NSDate *syncFinish = [NSDate date];
            NSTimeInterval executionTime = [syncFinish timeIntervalSinceDate:syncStart];
            NSLog(@"Address book sync executionTime = %f", executionTime);
            
            NSString *localInstallationId = [AppUtils localInstallationId];
            [AppUtils postTrackedTiming:executionTime withCategory:@"resources" andName:@"address book sync timing" andLabel:localInstallationId];
            [AppUtils postAnalyticsEventWithCategory:@"address_book_sync" andAction:@"post_total_favorited_ceaseless_contacts" andLabel:localInstallationId andValue: [NSNumber numberWithInteger:clc.numberOfFavoritedCeaselessContacts]];
            [AppUtils postAnalyticsEventWithCategory:@"address_book_sync" andAction:@"post_total_active_ceaseless_contacts" andLabel:localInstallationId andValue: [NSNumber numberWithInteger:clc.numberOfActiveCeaselessContacts]];
            [AppUtils postAnalyticsEventWithCategory:@"address_book_sync" andAction:@"post_total_removed_ceaseless_contacts" andLabel:localInstallationId andValue: [NSNumber numberWithInteger:clc.numberOfRemovedCeaselessContacts]];
            
            _syncing = NO;
			[[UIApplication sharedApplication] endBackgroundTask:self.backgroundTask];
			self.backgroundTask = UIBackgroundTaskInvalid;
        });
    }
}

- (void) refreshCeaselessContacts {
    NSArray * allAddressBookContacts;
    NSArray *allCeaselessContacts;
    allAddressBookContacts = [self getUnifiedAddressBookRecords:_addressBook];
    for (NSSet *unifiedRecord in allAddressBookContacts) {
        [self updateCeaselessContactFromABRecord:(__bridge ABRecordRef)[unifiedRecord anyObject]];
    }
    
    allCeaselessContacts = [self getAllCeaselessContacts];
    for (PersonIdentifier *person in allCeaselessContacts) {
        [self updateCeaselessContactLocalIds: person];
    }
    
    NSLog(@"Total person info records: %lu", (unsigned long) [self.getAllCeaselessPersonInfo count]);
    NSLog(@"Total address book records: %lu", (unsigned long) [allAddressBookContacts count]);
    NSLog(@"Total Ceaseless contacts: %lu", (unsigned long)[allCeaselessContacts count]);
}

- (NSNumber*) totalActiveCeaselessContacts {
    NSPredicate *filterRemovedContacts = [NSPredicate predicateWithFormat: @"removedDate = nil"];
    return [NSNumber numberWithUnsignedInteger: [self countFetchResultForEntityName:@"PersonIdentifier" withPredicate: filterRemovedContacts]];
}

- (NSUInteger) countFetchResultForEntityName: (NSString*) entityName withPredicate: (NSPredicate *) predicate {
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:entityName];
    [fetchRequest setPredicate:predicate];
    NSError *error = nil;
    return [self.managedObjectContext countForFetchRequest:fetchRequest error:&error];
}

- (void) initializeFirstContacts: (NSInteger) n {
    if (_addressBook) {
        NSArray *allAddressBookContacts = [self getUnifiedAddressBookRecords:_addressBook];
        n = MIN(n, [allAddressBookContacts count]);
        for(NSInteger i = 0; i < n; i++) {
            ABRecordRef rawPerson = (__bridge ABRecordRef)([allAddressBookContacts[i] anyObject]);
            [self updateCeaselessContactFromABRecord:rawPerson];
            CFRelease(rawPerson);
        }
    }
}

- (void) updateCeaselessContactLocalIds: (PersonIdentifier *) person {
    ABRecordRef rawPerson = NULL;
    for (AddressBookId *abId in person.addressBookIds) {
        rawPerson = ABAddressBookGetPersonWithRecordID(_addressBook, (ABRecordID) [abId.recordId intValue]);
        if (rawPerson != NULL) { // we got one that points to a record
            // check if the record matches our original person contact, since it could be something else entirely
            PersonIdentifier *validatedPerson = [self getCeaselessContactFromABRecord:rawPerson];
            if(validatedPerson != person) {
                // we are pointing to a record that is not pointing back to us
                // prune it from our list of local ids.
                NSMutableOrderedSet *addressBookIds = [[NSMutableOrderedSet alloc] initWithOrderedSet:person.addressBookIds];
                [addressBookIds removeObject:abId];
                person.addressBookIds = addressBookIds;
            }
        } else {
            // we are pointing to a record that is not pointing back to us
            // prune it from our list of local ids.
            NSMutableOrderedSet *addressBookIds = [[NSMutableOrderedSet alloc] initWithOrderedSet:person.addressBookIds];
            [addressBookIds removeObject:abId];
            person.addressBookIds = addressBookIds;
            if ([addressBookIds count] == 0) {
                // the contact was removed from the system.
                NSDate *now = [NSDate date];
                person.removedDate = now;
                person.systemRemovedDate = now;
                // things to keep in mind:
                // this contact will basically be frozen until an address book record matching it
                // exists again
                // the associated PersonInfo will not be updated.
                // the indication that this was removed from the local system itself
                // is that the systemRemovedDate is not nil and
                // the addressBookIds set is empty.
                // updateCeaselessContactFromABRecord and buildCeaselessContact
                // are where this contact can be "un-frozen" and re-added to the system.
            }
        }
    }
    
    // replace the primary record if the old one is no longer valid.
    if ([person.addressBookIds count] > 0 && ![person.addressBookIds containsObject: person.representativeInfo.primaryAddressBookId]) {
        person.representativeInfo.primaryAddressBookId = person.addressBookIds[0];
    }
    
    // save
    NSError *error;
    if (![self.managedObjectContext save:&error]) {
        NSLog(@"%s: Problem saving: %@", __PRETTY_FUNCTION__, error);
    }
}

#pragma mark - Manipulating records
- (NSArray *)getUnifiedAddressBookRecords:(ABAddressBookRef)addressBook {
    _addressBook = addressBook;
    // http://stackoverflow.com/questions/11351454/dealing-with-duplicate-contacts-due-to-linked-cards-in-ios-address-book-api
    NSMutableSet *unifiedRecordsSet = [NSMutableSet set];
    
    CFArrayRef records = ABAddressBookCopyArrayOfAllPeopleInSource(addressBook, kABSourceTypeLocal);
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

- (NSArray *) getAllActiveCeaselessContacts {
    NSPredicate *filterRemovedContacts = [NSPredicate predicateWithFormat: @"removedDate = nil"];
    return [self fetchEntityForName:@"PersonIdentifier" withPredicate: filterRemovedContacts];
}

- (NSInteger) numberOfActiveCeaselessContacts {
    NSPredicate *filterRemovedContacts = [NSPredicate predicateWithFormat: @"removedDate = nil"];
    return [self numberOfContactsForPredicate:filterRemovedContacts];
}
- (NSInteger) numberOfFavoritedCeaselessContacts {
    NSPredicate *favoritedContacts = [NSPredicate predicateWithFormat: @"favoritedDate != nil"];
    return [self numberOfContactsForPredicate:favoritedContacts];
}

- (NSInteger) numberOfRemovedCeaselessContacts {
    NSPredicate *favoritedContacts = [NSPredicate predicateWithFormat: @"removedDate != nil"];
    return [self numberOfContactsForPredicate:favoritedContacts];
}

- (NSInteger) numberOfContactsForPredicate: (NSPredicate *) predicate {
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"PersonIdentifier"
                                              inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    [fetchRequest setPredicate:predicate];
    NSError * error = nil;
    NSInteger peopleCount = [self.managedObjectContext countForFetchRequest:fetchRequest error:&error];
    
    return peopleCount;
}

- (NSArray *) getAllCeaselessContacts {
    return [self fetchEntityForName:@"PersonIdentifier"];
}

- (NSArray *) getAllCeaselessPersonInfo {
    return [self fetchEntityForName:@"PersonInfo"];
}

- (NSArray *) getAllNames {
    return [self fetchEntityForName:@"Name"];
}

- (NSArray *) getAllAddressBookIds {
    return [self fetchEntityForName:@"AddressBookId"];
}

- (NSArray *) fetchEntityForName: (NSString*) name withPredicate: (NSPredicate*) predicate {
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:name
                                              inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    if (predicate != nil) {
        [fetchRequest setPredicate:predicate];
    }

    NSError * error = nil;
    NSArray *results = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    
    if(results == nil) {
        NSLog(@"Fetch error: %@", error);
    }
    
    return results;
}

- (NSArray *) fetchEntityForName: (NSString*) name {
    return [self fetchEntityForName:name withPredicate:nil];
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

- (UIImage *) getImageForPersonIdentifier: (PersonIdentifier *) person {
    ABRecordRef rawPerson;
    for(AddressBookId *abId in person.addressBookIds) {
        rawPerson = ABAddressBookGetPersonWithRecordID(_addressBook, (ABRecordID) [abId.recordId intValue]);
        // Check for contact picture
        if (rawPerson != nil && ABPersonHasImageData(rawPerson)) {
            if ( &ABPersonCopyImageDataWithFormat != nil ) {
                return [UIImage imageWithData:(__bridge NSData *)ABPersonCopyImageDataWithFormat(rawPerson, kABPersonImageFormatOriginalSize)];
            }
        }
    }
    
    //default return nothing.
    return nil;
}

- (NSString*) initialsForPerson: (PersonIdentifier *) person {
    PersonInfo *info = person.representativeInfo;
    // deal with cases of no lastName or firstName
    // We had an Akbar (null) name show up.
    NSString *firstInitial = @" "; // 1 character space for initials if needed
    NSString *lastInitial = @" "; // 1 character space for initials if needed
    
    if([info.primaryFirstName.name length] > 0) {
        firstInitial = [info.primaryFirstName.name substringToIndex: 1];
    }
    if([info.primaryLastName.name length] > 0) {
        lastInitial = [info.primaryLastName.name substringToIndex: 1];
    }
    
    return [NSString stringWithFormat: @"%@%@", firstInitial, lastInitial];
}

- (NSString*) compositeNameForPerson: (PersonIdentifier *) person {
    NSString *firstName = @" ";
    NSString *lastName = @" ";
    
    PersonInfo *info = person.representativeInfo;
    if([info.primaryFirstName.name length] > 0) {
        firstName = info.primaryFirstName.name;
    }
    if([info.primaryLastName.name length] > 0) {
        lastName = info.primaryLastName.name;
    }
    
    return [NSString stringWithFormat: @"%@ %@", firstName, lastName];
}

- (void) createPersonInfoForCeaselessContact: (PersonIdentifier*) person {
    PersonInfo *newCeaselessPersonInfo = [NSEntityDescription insertNewObjectForEntityForName:@"PersonInfo" inManagedObjectContext:self.managedObjectContext];
    PersonInfo *oldPersonInfo = person.representativeInfo;
    newCeaselessPersonInfo.identifier = person;
    // the first entry is always the primary address book id for consistency
    newCeaselessPersonInfo.primaryAddressBookId = person.addressBookIds[0];
    
    // we always try to enrich our contact information from all linked records
    // beginning with the primary address book id.
    for (AddressBookId *abId in person.addressBookIds) {
        ABRecordRef rawPerson;
        rawPerson = ABAddressBookGetPersonWithRecordID(_addressBook, (ABRecordID) [abId.recordId intValue]);

        if (newCeaselessPersonInfo.primaryFirstName == nil || newCeaselessPersonInfo.primaryLastName == nil) {
            NSString *primaryFirstName = CFBridgingRelease(ABRecordCopyValue(rawPerson, kABPersonFirstNameProperty));
            NSString *primaryLastName = CFBridgingRelease(ABRecordCopyValue(rawPerson, kABPersonLastNameProperty));
            NSPredicate *predicate = [NSPredicate predicateWithFormat: @"name = %@", primaryFirstName];
            newCeaselessPersonInfo.primaryFirstName = (Name*)[self getOrCreateManagedObject:@"Name" withPredicate:predicate];
            predicate = [NSPredicate predicateWithFormat: @"name = %@", primaryLastName];
            newCeaselessPersonInfo.primaryLastName = (Name*)[self getOrCreateManagedObject:@"Name" withPredicate:predicate];
        }
        
        // TODO:  this needs to be mobile or iphone first the other because it is used for texting from the device
        if(newCeaselessPersonInfo.primaryPhoneNumber == nil) {
            ABMultiValueRef phoneNumbers = ABRecordCopyValue(rawPerson, kABPersonPhoneProperty);
            CFIndex numberOfPhoneNumbers = ABMultiValueGetCount(phoneNumbers);
            for (CFIndex i = 0; i < numberOfPhoneNumbers; i++) {
                NSString *phoneNumber = CFBridgingRelease(ABMultiValueCopyValueAtIndex(phoneNumbers, i));
                NSPredicate *predicate = [NSPredicate predicateWithFormat:
                                          @"number = %@", phoneNumber];
                PhoneNumber *phoneNumberObject = (PhoneNumber *) [self getOrCreateManagedObject: @"PhoneNumber" withPredicate:predicate];
                phoneNumberObject.number = phoneNumber;
                newCeaselessPersonInfo.primaryPhoneNumber = phoneNumberObject;
            }
            CFRelease(phoneNumbers);
        }
        
        if(newCeaselessPersonInfo.primaryEmail == nil) {
            ABMultiValueRef emails = ABRecordCopyValue(rawPerson, kABPersonEmailProperty);
            CFIndex numberOfEmails = ABMultiValueGetCount(emails);
            for (CFIndex i = 0; i < numberOfEmails; i++) {
                NSString *email = CFBridgingRelease(ABMultiValueCopyValueAtIndex(emails, i));
                NSPredicate *predicate = [NSPredicate predicateWithFormat:
                                          @"address = %@", email];
                Email *emailObject = (Email *) [self getOrCreateManagedObject: @"Email" withPredicate:predicate];
                emailObject.address = email;
                newCeaselessPersonInfo.primaryEmail = emailObject;
            }
            CFRelease(emails);
        }
    }
    
    if(oldPersonInfo != nil) {
        [self.managedObjectContext deleteObject: oldPersonInfo];
    }
    
    // save our changes
    NSError *error;
    if (![self.managedObjectContext save:&error]) {
        NSLog(@"%s: Problem saving: %@", __PRETTY_FUNCTION__, error);
    }
}

- (PersonIdentifier *) getCeaselessContactFromABRecord: (ABRecordRef) rawPerson {
    // first look up by id
    NSString *addressBookId = @(ABRecordGetRecordID(rawPerson)).stringValue;
    NSArray *resultsByDeviceAndAddressBookId = [self lookupContactsByAddressBookId: addressBookId];
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
    
    NSArray *resultsByName = [self lookupContactsByFirstName:firstName andLastName:lastName];
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
    
    NSArray *resultsFilteredByPhoneOrEmail = [self filterResults:resultsByName byEmails:emails orPhoneNumbers:phoneNumbers];
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

- (PersonIdentifier *) getCeaselessContactFromCeaselessId: (NSString *) ceaselessId {
    NSManagedObjectContext *context = [self managedObjectContext];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"PersonIdentifier" inManagedObjectContext:context];
    [request setEntity:entity];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:
                              @"ceaselessId = %@", ceaselessId];
    [request setPredicate:predicate];
    NSError *errorFetch = nil;
    NSArray *existingResults = [context executeFetchRequest:request error:&errorFetch];
    if([existingResults count] < 1) {
        return nil;
    } else {
        return existingResults[0];
    }
}

- (PersonIdentifier *) createCeaselessContactFromABRecord: (ABRecordRef) rawPerson {
    PersonIdentifier *newCeaselessPerson = [NSEntityDescription insertNewObjectForEntityForName:@"PersonIdentifier" inManagedObjectContext:self.managedObjectContext];
    [self buildCeaselessContact:newCeaselessPerson fromABRecord:rawPerson];
    NSUUID  *UUID = [NSUUID UUID];
    newCeaselessPerson.ceaselessId = [UUID UUIDString];
    // save our changes
    NSError *error;
    if (![self.managedObjectContext save:&error]) {
        NSLog(@"%s: Problem saving: %@", __PRETTY_FUNCTION__, error);
    }

    [self createPersonInfoForCeaselessContact:newCeaselessPerson];
    return newCeaselessPerson;
}

- (PrayerRecord *) createPrayerRecordForPerson: (PersonIdentifier*) person {
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
        if (firstName != nil && ![firstName isEqual: @""] && ![firstName hasPrefix:@"#"]) {
            // if the first name is not nil or blank
            // and does not begin with # (as in #BAL and other special codes)
            // then we accept it.
            hasFirstName = YES;
        }
        
        PersonIdentifier *ceaselessContact = [self getCeaselessContactFromABRecord:personData];
        if(ceaselessContact != nil) {
            [matchingCeaselessContacts addObject: ceaselessContact];
        }
    }
    NSUInteger resultSize = [matchingCeaselessContacts count];
    
    if (hasFirstName) { // only operate on records with a first name
        if (resultSize == 1) {
            PersonIdentifier *ceaselessContact = [matchingCeaselessContacts anyObject];
            [self buildCeaselessContact:ceaselessContact fromABRecord:rawPerson];
            [self createPersonInfoForCeaselessContact:ceaselessContact];
        } else if(resultSize > 1) {
            // when we get multiple, keep the first
            PersonIdentifier *personToKeep = [matchingCeaselessContacts anyObject];
            [matchingCeaselessContacts removeObject: personToKeep];
            [self createPersonInfoForCeaselessContact:personToKeep];
            // remove the rest
            for(PersonIdentifier *personToRemove in matchingCeaselessContacts) {
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

- (void) buildCeaselessContact:(PersonIdentifier*) ceaselessContact fromABRecord: (ABRecordRef) rawPerson {
    NSSet *unifiedRecord = [self getUnifiedAddressBookRecordFor:rawPerson];
    ceaselessContact.firstNames = [self buildFirstNames:unifiedRecord];
    ceaselessContact.lastNames = [self buildLastNames:unifiedRecord];
    ceaselessContact.addressBookIds = [self buildAddressBookIds:unifiedRecord];
    ceaselessContact.phoneNumbers = [self buildPhoneNumbers:unifiedRecord];
    ceaselessContact.emails = [self buildEmails:unifiedRecord];
    if(ceaselessContact.systemRemovedDate != nil) {
        // if we are rebuilding this contact from ABRecords it is no longer removed on the system.
        ceaselessContact.systemRemovedDate = nil;
        ceaselessContact.removedDate = nil;
    }
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

- (NSMutableOrderedSet*)buildAddressBookIds:(NSSet *)unifiedRecord {
    
    NSUUID *oNSUUID = [[UIDevice currentDevice] identifierForVendor];
    NSString *deviceId = [oNSUUID UUIDString];
    NSMutableOrderedSet *addressBookIds = [[NSMutableOrderedSet alloc]init];
    
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
    } else {
        result = existingResults[0];
    }
    return result;
}

- (void) copyDataFromCeaselessContact: (PersonIdentifier *) src toContact: (PersonIdentifier *) dst {
    
    // we favorite the contact if one of them has been favorited
    if (src.favoritedDate != nil && dst.favoritedDate == nil) {
        dst.favoritedDate = src.favoritedDate;
    }
    
    // we keep a contact unless both have been removed
    if(src.removedDate == nil) {
        dst.removedDate = nil;
    }
    
    // if at least one is not system removed, we keep it.
    if(dst.systemRemovedDate != nil && src.systemRemovedDate == nil) {
        dst.systemRemovedDate = nil;
    }
    
    // for each relationship, change the id of the relationship to point to the id of the one we want to keep
    // apple core data generated code has a bug, so we have to do it this way
    // http://stackoverflow.com/questions/7385439/exception-thrown-in-nsorderedset-generated-accessors
    // http://stackoverflow.com/questions/7385439/exception-thrown-in-nsorderedset-generated-accessors/26676124#26676124
    NSMutableOrderedSet* tempOrderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:src.addressBookIds];
    [tempOrderedSet addObjectsFromArray:[dst.addressBookIds array]];
    dst.addressBookIds = tempOrderedSet;
    
    [dst addFirstNames:src.firstNames];
    [dst addLastNames:src.lastNames];
    [dst addPhoneNumbers:src.phoneNumbers];
    [dst addEmails:src.emails];
    
    [dst addNotes: src.notes];
    [dst addPrayerRecords:src.prayerRecords];
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
