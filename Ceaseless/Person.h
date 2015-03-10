//
//  Person.h
//  Ceaseless
//
//  Created by Lori Hill on 3/10/15.
//  Copyright (c) 2015 Christopher Lim. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Note, PeopleQueue, PhoneNumber;

@interface Person : NSManagedObject

@property (nonatomic, retain) NSString * firstName;
@property (nonatomic, retain) NSString * lastName;
@property (nonatomic, retain) NSString * ceaselessId;
@property (nonatomic, retain) NSString * addressBookId;
@property (nonatomic, retain) NSSet *emails;
@property (nonatomic, retain) NSSet *phoneNumbers;
@property (nonatomic, retain) NSSet *notes;
@property (nonatomic, retain) NSSet *prayerRecords;
@property (nonatomic, retain) PeopleQueue *queued;
@end

@interface Person (CoreDataGeneratedAccessors)

- (void)addEmailsObject:(NSManagedObject *)value;
- (void)removeEmailsObject:(NSManagedObject *)value;
- (void)addEmails:(NSSet *)values;
- (void)removeEmails:(NSSet *)values;

- (void)addPhoneNumbersObject:(PhoneNumber *)value;
- (void)removePhoneNumbersObject:(PhoneNumber *)value;
- (void)addPhoneNumbers:(NSSet *)values;
- (void)removePhoneNumbers:(NSSet *)values;

- (void)addNotesObject:(Note *)value;
- (void)removeNotesObject:(Note *)value;
- (void)addNotes:(NSSet *)values;
- (void)removeNotes:(NSSet *)values;

- (void)addPrayerRecordsObject:(NSManagedObject *)value;
- (void)removePrayerRecordsObject:(NSManagedObject *)value;
- (void)addPrayerRecords:(NSSet *)values;
- (void)removePrayerRecords:(NSSet *)values;

@end
