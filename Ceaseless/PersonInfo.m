//
//  PersonInfo.m
//  Ceaseless
//
//  Created by Christopher Lim on 4/3/15.
//  Copyright (c) 2015 Christopher Lim. All rights reserved.
//

#import "PersonInfo.h"
#import "AddressBookId.h"
#import "Email.h"
#import "Name.h"
#import "PersonIdentifier.h"
#import "PhoneNumber.h"


@implementation PersonInfo

@dynamic identifier;
@dynamic primaryAddressBookId;
@dynamic primaryEmail;
@dynamic primaryFirstName;
@dynamic primaryLastName;
@dynamic primaryPhoneNumber;

	//this is a transient property, not part of the model, used to fix nil and caseInsensitive inconsistencies in the index
-(NSString*) sectionLastName {

	NSString *temp = [self.primaryLastName.name uppercaseString];
	if (!temp.length || temp.length == 1) {
		return temp ? temp : @"";
	}
	return temp ? [temp substringToIndex:1] : @"";
}
@end
