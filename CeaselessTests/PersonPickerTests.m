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
@end

@implementation PersonPickerTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample {
    // This is an example of a functional test case.
    XCTAssert(YES, @"Pass");
}

@end