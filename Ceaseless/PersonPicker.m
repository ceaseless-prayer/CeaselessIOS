//
//  AddressBook.m
//  Ceaseless
//
//  Created by Lori Hill on 3/3/15.
//  Copyright (c) 2015 Christopher Lim. All rights reserved.
//

#import "PersonPicker.h"
#import "AppDelegate.h"
#import "CeaselessLocalContacts.h"
#import "PrayerRecord.h"
#import "PeopleQueue.h"
#import "AppConstants.h"

@interface PersonPicker ()

@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) CeaselessLocalContacts *ceaselessContacts;
@property (nonatomic) ABAddressBookRef addressBook;
@property (nonatomic) NSInteger numberOfPeople;

@end

@implementation PersonPicker

- (instancetype) init {
    self = [super init];
    if (self) {
        AppDelegate *appDelegate = (id) [[UIApplication sharedApplication] delegate];
        
        NSInteger dailyPersonCount;
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

        if(![defaults integerForKey: kDailyPersonCount]) {
            // set default daily count
            [defaults setInteger:5 forKey: kDailyPersonCount];
            [defaults synchronize];
        }
        dailyPersonCount = [defaults integerForKey:kDailyPersonCount];
        
        [self initializeAddressBook];
        self.managedObjectContext = appDelegate.managedObjectContext;
        self.numberOfPeople = dailyPersonCount;
        self.ceaselessContacts =  [CeaselessLocalContacts sharedCeaselessLocalContacts];
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
    // TODO figure out when we release the address book.
    //        if (_addressBook) CFRelease(_addressBook);
    
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
            } else {
                // however, if they didn't give you permission, handle it gracefully, for example...
                dispatch_async(dispatch_get_main_queue(), ^{
                    // BTW, this is not on the main thread, so dispatch UI updates back to the main queue
                    [[[UIAlertView alloc] initWithTitle:nil message:@"This app requires access to your contacts to function properly. Please visit to the \"Privacy\" section in the iPhone Settings app." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
                });
            }
        });
        
    } else if (status == kABAuthorizationStatusAuthorized) {
        NSLog(@"Address Book initialized");
    }
}

#pragma mark - Selecting people to show
- (void) pickPeople {
    NSInteger numberOfPeople = _numberOfPeople;

    // in case you didn't notice, the following line is beautiful.
    NSSortDescriptor *prayerRecordCountDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"prayerRecords.@max.createDate" ascending:YES];
    // TODO switch ascending to YES for prod. NO makes the people we pick more stable on each run.

    // filter out removed contacts
    NSPredicate *filterRemovedContacts = [NSPredicate predicateWithFormat: @"removedDate = nil"];
    NSArray *ceaselessPeople = [[[_ceaselessContacts getAllCeaselessContacts] filteredArrayUsingPredicate:filterRemovedContacts] sortedArrayUsingDescriptors:[NSArray arrayWithObject:prayerRecordCountDescriptor]];
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
        PersonIdentifier *personToShow = ceaselessPeople[i];
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

- (BOOL) pickPersonIfPossible: (PersonIdentifier *) personToPick {
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
            PersonIdentifier *validatedPerson = [_ceaselessContacts getCeaselessContactFromABRecord:rawPerson];
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

- (PeopleQueue*) queuePerson: (PersonIdentifier*) person {
    [_ceaselessContacts createPrayerRecordForPerson: person];
    PeopleQueue *pq = [NSEntityDescription insertNewObjectForEntityForName:@"PeopleQueue" inManagedObjectContext:self.managedObjectContext];
    pq.person = person;
    // save our changes
    NSError *error;
    if (![self.managedObjectContext save:&error]) {
        NSLog(@"%s: Problem saving: %@", __PRETTY_FUNCTION__, error);
    }
    return pq;
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
@end
