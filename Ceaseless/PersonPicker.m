//
//  AddressBook.m
//  Ceaseless
//
//  Created by Lori Hill on 3/3/15.
//  Copyright (c) 2015 Christopher Lim. All rights reserved.
//

#import "PersonPicker.h"
#import <AddressBookUI/AddressBookUI.h>
#import "Person.h"
#import "AppDelegate.h"

@interface PersonPicker ()

@property (strong, nonatomic) NSMutableArray *ceaselessPeople;

@end

@implementation PersonPicker

-(void)loadContacts{


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

- (void)pickPeopleInAddressBook:(ABAddressBookRef)addressBook
{
//	NSInteger numberOfPeople = ABAddressBookGetPersonCount(addressBook);
	NSInteger numberOfPeople = 5;

	NSArray *allPeople = CFBridgingRelease(ABAddressBookCopyArrayOfAllPeople(addressBook));
    
    // http://stackoverflow.com/questions/11351454/dealing-with-duplicate-contacts-due-to-linked-cards-in-ios-address-book-api
    NSMutableSet *unifiedRecordsSet = [NSMutableSet set];
    
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
    
    allPeople = [unifiedRecordsSet allObjects];
    
	for (NSInteger i = 0; i < numberOfPeople; i++) {
        NSSet *unifiedRecord = allPeople[i];
        Person *person = [[Person alloc] init];
        
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
@end
