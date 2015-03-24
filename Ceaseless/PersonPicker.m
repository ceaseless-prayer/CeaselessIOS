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
#import "PeopleQueue.h"

@interface PersonPicker ()

@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) CeaselessLocalContacts *ceaselessContacts;
@property (nonatomic) ABAddressBookRef addressBook;
@property (nonatomic) NSInteger numberOfPeople;

@end

@implementation PersonPicker

- (instancetype) init {
    AppDelegate *appDelegate = (id) [[UIApplication sharedApplication] delegate];
	int dailyPersonCount;
	if ([[NSUserDefaults standardUserDefaults] doubleForKey:@"DailyPersonCount"]) {
		dailyPersonCount= [[NSUserDefaults standardUserDefaults] doubleForKey:@"DailyPersonCount"];
	} else {
		dailyPersonCount = 5;
	}
    

    return [self initWith: appDelegate.managedObjectContext numberOfPeople: dailyPersonCount];
}

- (instancetype) initWith: (NSManagedObjectContext*) managedObjectContext numberOfPeople: (int) numberOfPeople {
    self = [super init];
    if (self) {
        self.managedObjectContext = managedObjectContext;
        _numberOfPeople = numberOfPeople;
        self.ceaselessContacts = [[CeaselessLocalContacts alloc]init];
        _ceaselessContacts.contacts = [[NSMutableArray alloc] initWithArray:[self getAllCeaselessContacts]];
        _ceaselessContacts.names = [[NSMutableArray alloc] initWithArray:[self getAllNames]];
        _ceaselessContacts.addressBookIds = [[NSMutableArray alloc] initWithArray:[self getAllAddressBookIds]];
        
        [self initializeAddressBook];
    }
    return self;
}

- (void)initializeAddressBook {
    // get address book authorization
    ABAuthorizationStatus status = ABAddressBookGetAuthorizationStatus();
    if (status == kABAuthorizationStatusDenied) {
        // if you got here, user had previously denied/revoked permission for your
        // app to access the contacts, and all you can do is handle this gracefully,
        // perhaps telling the user that they have to go to settings to grant access
        // to contacts
        [[[UIAlertView alloc] initWithTitle:nil message:@"This app requires access to your contacts to function properly. Please visit to the \"Privacy\" section in the iPhone Settings app." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
    }
    
    CFErrorRef error = NULL;
    _addressBook = ABAddressBookCreateWithOptions(NULL, &error);
    
    if (error) {
        NSLog(@"ABAddressBookCreateWithOptions error: %@", CFBridgingRelease(error));
        if (_addressBook) CFRelease(_addressBook);
    }
    
    if (status == kABAuthorizationStatusNotDetermined) {
        // present the user the UI that requests permission to contacts ...
        ABAddressBookRequestAccessWithCompletion(_addressBook, ^(bool granted, CFErrorRef error) {
            if (error) {
                NSLog(@"ABAddressBookRequestAccessWithCompletion error: %@", CFBridgingRelease(error));
            }
            
            if (granted) {
                // TODO this should probably be a notification
                // which then kicks off the initalization process.
                // show a housekeeping loading view and hide it when the process is done.
                // if they gave you permission, then just carry on
                // send out notification that permission is granted.
                // we can detect the notification, kick off ensureContactsAreInitializedAndRefreshed
                // and show the UI.
                [self ensureContactsAreInitializedAndRefreshed]; // TODO refresh UI to show them now.
            } else {
                // however, if they didn't give you permission, handle it gracefully, for example...
                dispatch_async(dispatch_get_main_queue(), ^{
                    // BTW, this is not on the main thread, so dispatch UI updates back to the main queue
                    [[[UIAlertView alloc] initWithTitle:nil message:@"This app requires access to your contacts to function properly. Please visit to the \"Privacy\" section in the iPhone Settings app." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
                });
            }
            if (_addressBook) CFRelease(_addressBook);
        });
        
    } else if (status == kABAuthorizationStatusAuthorized) {
        NSLog(@"Address Book initialized");
    }
}

- (void) ensureContactsAreInitializedAndRefreshed {
    // initial load when we have no Ceaseless contacts whatsoever.
    if([_ceaselessContacts.contacts count] == 0) {
        // preload the first 5 contacts
        [self initializeFirstContacts:_numberOfPeople];
    }
    [self pickPeople];
    if (_addressBook) CFRelease(_addressBook);
    
    // refresh address book in the background
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        CFErrorRef error = NULL;
        ABAddressBookRef addressBook2 = ABAddressBookCreateWithOptions(NULL, &error);
        
        NSManagedObjectContext *managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        [managedObjectContext setParentContext:self.managedObjectContext];
        
        // initialize a new personpicker
        PersonPicker *pp =  [[PersonPicker alloc]initWith:managedObjectContext numberOfPeople:5];
        pp.addressBook = addressBook2;
        [pp.managedObjectContext performBlockAndWait: ^{
            [pp refreshCeaselessContacts];
        }];
        
        if (addressBook2) CFRelease(addressBook2);
    });
}

// this method is run to get new people to pray for.
- (void) loadContacts {
    if(ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusAuthorized) {
        [self emptyQueue];
        [self ensureContactsAreInitializedAndRefreshed];
    }
}

#pragma mark - Selecting people to show
- (void)pickPeople
{
    NSInteger numberOfPeople = _numberOfPeople;

    // in case you didn't notice, the following line is beautiful.
    NSSortDescriptor *prayerRecordCountDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"prayerRecords.@max.createDate" ascending:YES];
    // TODO switch ascending to YES for prod. NO makes the people we pick more stable on each run.

    // filter out removed contacts
    NSPredicate *filterRemovedContacts = [NSPredicate predicateWithFormat: @"removedDate = nil"];
    NSArray *ceaselessPeople = [[[self getAllCeaselessContacts] filteredArrayUsingPredicate:filterRemovedContacts] sortedArrayUsingDescriptors:[NSArray arrayWithObject:prayerRecordCountDescriptor]];
    NSLog(@"Total filtered Ceaseless contacts: %lu", (unsigned long)[ceaselessPeople count]);
    
    // first get at least one contact who has been favorited if any are available.
    NSPredicate *keepFavoriteContacts = [NSPredicate predicateWithFormat: @"favoritedDate != nil"];
    NSArray *favoriteContacts = [ceaselessPeople filteredArrayUsingPredicate: keepFavoriteContacts];
    if ([favoriteContacts count] > 0) {
        BOOL pickFavoriteContact = YES;
        
        // when you have less than 7 favorited contacts
        // it will only pick a favorite to show with a probability of 1/3
        // otherwise you could be seeing the same person every single day.
        if([favoriteContacts count] < 7) {
            NSInteger diceRoll =  arc4random_uniform(3);
            if(diceRoll != 0) {
                pickFavoriteContact = NO;
            }
        }
        // TODO remove this override for prod. We always show favorites for test.
        pickFavoriteContact = YES;
        
        // if only 1 has been favorite, don't just show it every single day...
        if(pickFavoriteContact && [self pickPersonIfPossible:favoriteContacts[0]]) {
            --numberOfPeople;
        }
    }
    
    // fill in the rest of the queue with contacts--take the one who has either never been prayed for
    // or who has not been prayed for in a long time.
    
    if ([ceaselessPeople count] < numberOfPeople) {
        numberOfPeople = [ceaselessPeople count];
    }
    
    for (NSInteger i = 0; i< numberOfPeople; i++) {
        Person *personToShow = ceaselessPeople[i];
        BOOL personPicked = [self pickPersonIfPossible:personToShow];
        
        if(!personPicked) {
            NSLog(@"Could not pick %@", personToShow);
            // we gotta loop through again if we haven't picked someone yet.
            if (numberOfPeople < [ceaselessPeople count]) {
                ++numberOfPeople;
            }
        }
    }
}

- (BOOL) pickPersonIfPossible: (Person *) personToPick {
    // you can't pick a person who has already been picked.
    NSArray *queuedPeople = [self queuedPeople];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:
                              @"person = %@", personToPick];
    if([[queuedPeople filteredArrayUsingPredicate:predicate] count] > 0) {
        return NO;
    }
    
    ABRecordRef rawPerson = NULL;
    BOOL personHasBeenPicked = NO;
    
    for(AddressBookId *abId in personToPick.addressBookIds) { // try address book records until you have a valid one.
        rawPerson = ABAddressBookGetPersonWithRecordID(_addressBook, (ABRecordID) [abId.recordId intValue]);
        if (rawPerson != NULL) { // we got one that points to a record
            // check if the record matches our original person contact, since it could be something else entirely
            Person *validatedPerson = [self getCeaselessContactFromABRecord:rawPerson];
            if(validatedPerson == personToPick) {
                // since it matches, we can pick this person
                [self queuePerson:personToPick];
                personHasBeenPicked = YES;
                break;
            }
            // we gotta pick something else if it doesn't match
            // let background refresh processes solve the consistency issues.
        }
    }
    return personHasBeenPicked;
}

- (void) queuePerson: (Person*) person {
    [self createPrayerRecordForPerson: person];
    PeopleQueue *pq = [NSEntityDescription insertNewObjectForEntityForName:@"PeopleQueue" inManagedObjectContext:self.managedObjectContext];
    pq.person = person;
    // save our changes
    NSError *error;
    if (![self.managedObjectContext save:&error]) {
        NSLog(@"%s: Problem saving: %@", __PRETTY_FUNCTION__, error);
    }
}

- (NSArray *) queuedPeople {
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"PeopleQueue"
                                              inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    NSError * error = nil;
    NSArray *fetchedObjects = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    return fetchedObjects;
}

- (void) emptyQueue {
    for(PeopleQueue *pq in [self queuedPeople]) {
        [self.managedObjectContext deleteObject: pq];
    }
    NSError * error = nil;
    if (![self.managedObjectContext save:&error]) {
        NSLog(@"%s: Problem emptying queue: %@", __PRETTY_FUNCTION__, error);
    }
}

#pragma mark - Keeping Ceaseless and the address book in sync
- (void) refreshCeaselessContacts {
    NSArray * allAddressBookContacts = [self getUnifiedAddressBookRecords:_addressBook];
    
    NSLog(@"Total Ceaseless contacts: %lu", (unsigned long)[_ceaselessContacts.contacts count]);
    for (NSSet *unifiedRecord in allAddressBookContacts) {
        [self updateCeaselessContactFromABRecord:(__bridge ABRecordRef)[unifiedRecord anyObject]];
    }
    
    NSArray *allCeaselessContacts = [self getAllCeaselessContacts];
    for (Person *person in allCeaselessContacts) {
        [self updateCeaselessContactLocalIds: person fromAddressBook: _addressBook];
    }
}

- (void) initializeFirstContacts: (NSInteger) n {
    NSArray *allAddressBookContacts = [self getUnifiedAddressBookRecords:_addressBook];
    n = MIN(n, [allAddressBookContacts count]);
    for(NSInteger i = 0; i < n; i++) {
            [self updateCeaselessContactFromABRecord:(__bridge ABRecordRef)[allAddressBookContacts[i] anyObject]];
    }
}

- (void) updateCeaselessContactLocalIds: (Person *) person fromAddressBook: (ABAddressBookRef) addressBook {
    _addressBook = addressBook;
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
            // TODO if addressBookIds reaches count 0,
            // should we consider the Ceaseless Contact deleted from the address book?
            // should there be a separate clean up process for that?
        }
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

- (NonMOPerson *) getNonMOPersonForCeaselessContact: (Person*) person {
    NonMOPerson *nonMOPerson = [[NonMOPerson alloc] init];
    nonMOPerson.person = person;
    ABRecordRef rawPerson;
    for (AddressBookId *abId in person.addressBookIds) {
        rawPerson = ABAddressBookGetPersonWithRecordID(_addressBook, (ABRecordID) [abId.recordId intValue]);
        // Check for contact picture
        if (rawPerson != nil && ABPersonHasImageData(rawPerson)) {
            if ( &ABPersonCopyImageDataWithFormat != nil ) {
                nonMOPerson.profileImage = [UIImage imageWithData:(__bridge NSData *)ABPersonCopyImageDataWithFormat(rawPerson, kABPersonImageFormatOriginalSize)];
            }
        }
        
        nonMOPerson.firstName = CFBridgingRelease(ABRecordCopyValue(rawPerson, kABPersonFirstNameProperty));
        nonMOPerson.lastName  = CFBridgingRelease(ABRecordCopyValue(rawPerson, kABPersonLastNameProperty));

        // TODO:  this needs to be mobile or iphone first the other because it is used for texting from the device
    
        ABMultiValueRef phoneNumbers = ABRecordCopyValue(rawPerson, kABPersonPhoneProperty);
        
        CFIndex numberOfPhoneNumbers = ABMultiValueGetCount(phoneNumbers);
        for (CFIndex i = 0; i < numberOfPhoneNumbers; i++) {
            NSString *phoneNumber = CFBridgingRelease(ABMultiValueCopyValueAtIndex(phoneNumbers, i));
            nonMOPerson.phoneNumber = phoneNumber;
        }
        
        CFRelease(phoneNumbers);
    }
    return nonMOPerson;
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

- (Person *) getCeaselessContactFromCeaselessId: (NSString *) ceaselessId {
    NSManagedObjectContext *context = [self managedObjectContext];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Person" inManagedObjectContext:context];
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
