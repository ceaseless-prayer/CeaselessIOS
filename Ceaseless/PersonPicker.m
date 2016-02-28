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
#import "AppUtils.h"

@interface PersonPicker ()

@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) CeaselessLocalContacts *ceaselessContacts;
@property (nonatomic) ABAddressBookRef addressBook;
@property (nonatomic) NSInteger numberOfPeople;
@property (nonatomic, assign) BOOL addToQueue;

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
            [defaults setInteger:3 forKey: kDailyPersonCount];
            [defaults synchronize];
        }
        dailyPersonCount = [defaults integerForKey:kDailyPersonCount];
        
        _addressBook = [AppUtils getAddressBookRef];
        self.managedObjectContext = appDelegate.managedObjectContext;
        self.numberOfPeople = dailyPersonCount;
        self.ceaselessContacts =  [CeaselessLocalContacts sharedCeaselessLocalContacts];
    }
    return self;
}

- (NSUInteger) countFetchResultForEntityName: (NSString*) entityName withPredicate: (NSPredicate *) predicate {
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:entityName];
    [fetchRequest setPredicate:predicate];
    NSError *error = nil;
    return [self.managedObjectContext countForFetchRequest:fetchRequest error:&error];
}

- (NSArray *) computePrayerCycleProgress {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if(![defaults objectForKey:kPrayerCycleStartDate]) {
        // we set it to the past so the first run will still show progress.
        // the people have already been picked so the records would be prior
        // to the cycle start date otherwise.
        NSDate *oneHourAgo = [[NSDate date] dateByAddingTimeInterval:-60*60];
        [defaults setObject:oneHourAgo forKey:kPrayerCycleStartDate];
        [defaults synchronize];
        // this is the first time a cycle has started
        // the progress card needs to show something special in this case
        // because the contacts are probably not all synced yet.
        return @[[NSNumber numberWithInt:-1], [NSNumber numberWithInt: -1]];
    }
    
    NSDate *cycleStartDate = [defaults objectForKey:kPrayerCycleStartDate];
    
    // filter out removed contacts
    NSPredicate *filterRemovedContacts = [NSPredicate predicateWithFormat: @"removedDate = nil"];
    NSPredicate *peoplePrayedForThisCycle = [NSPredicate predicateWithFormat:@"prayerRecords.@max.createDate > %@", cycleStartDate];
    
    NSUInteger rawTotalPeople = [self countFetchResultForEntityName:@"PersonIdentifier" withPredicate: filterRemovedContacts];
    NSUInteger rawTotalPeoplePrayedForThisCycle = [self countFetchResultForEntityName:@"PersonIdentifier" withPredicate: peoplePrayedForThisCycle];
    if(rawTotalPeoplePrayedForThisCycle > rawTotalPeople) {
        // numerator should never exceed denominator
        rawTotalPeoplePrayedForThisCycle = rawTotalPeople;
    }
    
    NSNumber *totalPeople = [NSNumber numberWithUnsignedInteger: rawTotalPeople];
    NSNumber *totalPeoplePrayedForThisCycle = [NSNumber numberWithUnsignedInteger: rawTotalPeoplePrayedForThisCycle];
    NSLog(@"Prayer cycle progress: %@/%@", totalPeoplePrayedForThisCycle, totalPeople);
    
    // when everyone is prayed for restart the cycle.
    if (totalPeople == totalPeoplePrayedForThisCycle) {
        [defaults setObject:[NSDate date] forKey:kPrayerCycleStartDate];
        [defaults synchronize];
    }
    return @[totalPeoplePrayedForThisCycle, totalPeople];
}

#pragma mark - Selecting people to show
- (void) pickPeople {
    NSInteger numberOfPeople = _numberOfPeople;

    // in case you didn't notice, the following line is beautiful.
    NSSortDescriptor *prayerRecordCountDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"prayerRecords.@max.createDate" ascending:YES];
    // TODO switch ascending to YES for prod. NO makes the people we pick more stable on each run.

    // filter out removed contacts
    NSArray *ceaselessPeople = [[_ceaselessContacts getAllActiveCeaselessContacts] sortedArrayUsingDescriptors:[NSArray arrayWithObject:prayerRecordCountDescriptor]];
    NSLog(@"Total filtered Ceaseless contacts: %lu", (unsigned long)[ceaselessPeople count]);

		//the person picked previously to be shown in the notification for today
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString *ceaselessId = [defaults objectForKey:kPersonForNextDay];
	PersonIdentifier *personForNextDay = [_ceaselessContacts getCeaselessContactFromCeaselessId:ceaselessId]
;
	self.addToQueue = YES;
	BOOL personPicked = [self pickPersonIfPossible:personForNextDay];
	if(personPicked) {
		--numberOfPeople;
	}

		//fill today's queue from favorites, people with notes and others
	self.addToQueue = YES;
	[self pickPeople: (int)numberOfPeople fromArray: ceaselessPeople];

		//get the first person for the following day to show in the notification
	self.addToQueue = NO;
	numberOfPeople = 1;
	[self pickPeople: (int)numberOfPeople fromArray: ceaselessPeople];

}

- (void) pickPeople: (int)numberOfPeople fromArray: (NSArray *)ceaselessPeople {
	BOOL pickedFavorite = [self pickFavoriteFromArray: ceaselessPeople];
	if(pickedFavorite) {
		--numberOfPeople;
	}

		// if there is room for another person to pray for
		// preference those who have notes
	if(numberOfPeople > 0) {
		BOOL pickedPersonWithNotes = [self pickPersonWithNotesFromArray: ceaselessPeople];
		if(pickedPersonWithNotes) {
			--numberOfPeople;
		}
	}

		// fill in the rest of the queue with contacts--take the one who has either never been prayed for
		// or who has not been prayed for in a long time.

	if ([ceaselessPeople count] < numberOfPeople) {
		numberOfPeople = (int)[ceaselessPeople count];
	}

	[self pickMorePeopleForCount:(int)numberOfPeople inArray:ceaselessPeople];
}

- (BOOL) pickFavoriteFromArray: (NSArray *) ceaselessPeople {
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

			// if only 1 has been favorite, don't just show it every single day...
		if(pickFavoriteContact && [self pickPersonIfPossible:favoriteContacts[0]]) {
			return YES;
		} else {
			return NO;
		}
	} else {
		return NO;
	}
}

- (BOOL)pickPersonWithNotesFromArray: (NSArray *) ceaselessPeople {
	NSPredicate *keepContactsWithNotes = [NSPredicate predicateWithFormat: @"notes.@count > 0"];
	NSArray *contactsWithNotes = [ceaselessPeople filteredArrayUsingPredicate: keepContactsWithNotes];
	if ([contactsWithNotes count] > 0) {
		BOOL pickContactWithNotes = YES;
			// when you have less than 14 contacts with notes
			// it will only pick one to show with a probability of 1/6
			// so you are likely to get a person with a note once a week
		if([contactsWithNotes count] < 14) {
			NSInteger diceRoll =  arc4random_uniform(6);
			if(diceRoll != 0) {
				pickContactWithNotes = NO;
			}
		} else {
				// when you have more than 14 people with notes, you could get one everyday
				// and it would keep you occupied for over 2 weeks at a time.
				// so we show one with 50% probability
			NSInteger diceRoll =  arc4random_uniform(2);
			if(diceRoll != 0) {
				pickContactWithNotes = NO;
			}
		}

		if(pickContactWithNotes && [self pickPersonIfPossible:contactsWithNotes[0]]) {
			return YES;
		} else {
			return NO;
		}
	} else {
		return NO;
	}
}

- (void) pickMorePeopleForCount:(int)numberOfPeople inArray: (NSArray *)ceaselessPeople {
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
				if (self.addToQueue) {
					[self queuePerson:personToPick];
				} else {
					NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
					[defaults setObject: personToPick.ceaselessId forKey:kPersonForNextDay];
				}
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
