//
//  CeaselessContacts.h
//  Ceaseless
//
//  Created by Christopher Lim on 3/13/15.
//  Copyright (c) 2015 Christopher Lim. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AddressBookUI/AddressBookUI.h>
#import "AppDelegate.h"
#import "PrayerRecord.h"
#import "PersonIdentifier.h"
#import "PersonInfo.h"
#import "AddressBookId.h"
#import "Email.h"
#import "PhoneNumber.h"
#import "Name.h"

@interface CeaselessLocalContacts : NSObject
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (nonatomic) ABAddressBookRef addressBook;
@property (atomic) BOOL syncing;

+ (id) sharedCeaselessLocalContacts;
- (instancetype) initWithManagedObjectContext: (NSManagedObjectContext *) context andAddressBook: (ABAddressBookRef) addressBook;
- (instancetype) init;
- (NSArray *) filterResults: (NSArray*) results byEmails:(NSSet*) emails orPhoneNumbers: (NSSet*) phoneNumber;
- (NSArray *) lookupContactsByFirstName:(NSString*) firstName andLastName: (NSString*) lastName;
- (NSArray *) lookupContactsByAddressBookId:(NSString*) addressBookId;
- (PersonIdentifier *) getCeaselessContactFromABRecord: (ABRecordRef) rawPerson;
- (PersonIdentifier *) getCeaselessContactFromCeaselessId: (NSString *) ceaselessId;
- (void) updateCeaselessContactFromABRecord: (ABRecordRef) rawPerson;
- (PrayerRecord *) createPrayerRecordForPerson: (PersonIdentifier *) person;
- (PersonIdentifier *) createCeaselessContactFromABRecord: (ABRecordRef) rawPerson;
- (NSArray *) getAllCeaselessContacts;
- (UIImage *) getImageForPersonIdentifier: (PersonIdentifier *) person;
- (NSString*) initialsForPerson: (PersonIdentifier *) person;
- (NSString*) compositeNameForPerson: (PersonIdentifier *) person;
- (void) initializeFirstContacts: (NSInteger) n;
- (void) refreshCeaselessContacts;
- (void) ensureCeaselessContactsSynced;
@end
