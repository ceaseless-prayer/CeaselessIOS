//
//  PersonPickerTests.m
//  Ceaseless
//
//  Created by Christopher Lim on 3/12/15.
//  Copyright (c) 2015 Christopher Lim. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "PersonPicker.h"

@interface PersonPickerTests : XCTestCase
    @property (nonatomic) PersonPicker *picker;
- (void) setupAddressBookWithEntries: (NSArray *) entries;
@end

@implementation PersonPickerTests

- (void)setUp {
    [super setUp];
    _picker = [[PersonPicker alloc] init];
    // TODO start with a clean slate address book and ceaseless contacts
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testRefreshContactsFromAddressBook {
    // Given an address book with 3 entries
    [self setupAddressBookWithEntries: [[NSArray alloc] init]];
    // And no Ceaseless contacts
    [self setupCeaselessContactsWithEntries:[[NSArray alloc] init]];
    // When refresh is called
    //[_picker refreshContactsFromAddressBook:a];
    // Then there should be 3 Ceaseless contacts
    [self getCeaselessContacts];
    XCTAssert(YES, @"Pass");
    
    
    // Given an address book with 3 entries
    // And 2 matching Ceaseless contacts
    // When refresh is called
    // Then one contact should be added
    
    // Given an address book with 0 entries
    // And 2 Ceaseless contacts
    // When refresh is called
    // Then there should be no ceaseless contacts
    
    // Given an address book with 3 entries
    // And 3 matching Ceaseless contacts
    // When refresh is called
    // Then there should be no change
    
    // Given an address book with 3 entries
    // And 2 matching Ceaseless contacts
    // And 1 Ceaseless contact that matches on local id
    // When refresh is called
    // Then the fields of that 1 contact should be updated.
    
    // This is an example of a functional test case.
    XCTAssert(YES, @"Pass");
}

- (void) setupAddressBookWithEntries: (NSArray *) entries {
    
}

- (void) setupCeaselessContactsWithEntries: (NSArray *) entries {
    
}

- (void) getCeaselessContacts {
    
}

@end
