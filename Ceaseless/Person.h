//
//  Person.h
//  Ceaseless
//
//  Created by Christopher Lim on 3/13/15.
//  Copyright (c) 2015 Christopher Lim. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Email, Name, Note, PeopleQueue, PhoneNumber, PrayerRecord;

@interface Person : NSManagedObject

@property (nonatomic, retain) NSString * addressBookId;
@property (nonatomic, retain) NSString * ceaselessId;
@property (nonatomic, retain) NSSet *emails;
@property (nonatomic, retain) NSSet *notes;
@property (nonatomic, retain) NSSet *phoneNumbers;
@property (nonatomic, retain) NSSet *prayerRecords;
@property (nonatomic, retain) PeopleQueue *queued;
@property (nonatomic, retain) NSSet *firstNames;
@property (nonatomic, retain) NSSet *lastNames;
@end

@interface Person (CoreDataGeneratedAccessors)

- (void)addEmailsObject:(Email *)value;
- (void)removeEmailsObject:(Email *)value;
- (void)addEmails:(NSSet *)values;
- (void)removeEmails:(NSSet *)values;

- (void)addNotesObject:(Note *)value;
- (void)removeNotesObject:(Note *)value;
- (void)addNotes:(NSSet *)values;
- (void)removeNotes:(NSSet *)values;

- (void)addPhoneNumbersObject:(PhoneNumber *)value;
- (void)removePhoneNumbersObject:(PhoneNumber *)value;
- (void)addPhoneNumbers:(NSSet *)values;
- (void)removePhoneNumbers:(NSSet *)values;

- (void)addPrayerRecordsObject:(PrayerRecord *)value;
- (void)removePrayerRecordsObject:(PrayerRecord *)value;
- (void)addPrayerRecords:(NSSet *)values;
- (void)removePrayerRecords:(NSSet *)values;

- (void)addFirstNamesObject:(Name *)value;
- (void)removeFirstNamesObject:(Name *)value;
- (void)addFirstNames:(NSSet *)values;
- (void)removeFirstNames:(NSSet *)values;

- (void)addLastNamesObject:(Name *)value;
- (void)removeLastNamesObject:(Name *)value;
- (void)addLastNames:(NSSet *)values;
- (void)removeLastNames:(NSSet *)values;

@end
