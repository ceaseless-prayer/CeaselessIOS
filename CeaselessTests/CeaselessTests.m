//
//  CeaselessTests.m
//  CeaselessTests
//
//  Created by Christopher Lim on 3/2/15.
//  Copyright (c) 2015 Christopher Lim. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "AppUtils.h"

@interface CeaselessTests : XCTestCase

@end

@implementation CeaselessTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testDaysWithinEra {

    NSCalendar *gregorian = [[NSCalendar alloc]
                             initWithCalendarIdentifier:NSCalendarIdentifierGregorian];

    NSDate *now = [NSDate date];
    NSDateComponents *dateComponent = [gregorian components:NSCalendarUnitYear | NSCalendarUnitMinute | NSCalendarUnitSecond | NSCalendarUnitWeekday | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour fromDate: now];
    
    dateComponent.hour = 8;
    dateComponent.minute = 0;
    dateComponent.second = 0;
    dateComponent.day = 1;
    NSDate *start = [[NSCalendar currentCalendar] dateFromComponents:dateComponent];
    
    dateComponent = [gregorian components:NSCalendarUnitYear | NSCalendarUnitMinute | NSCalendarUnitSecond | NSCalendarUnitWeekday | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour fromDate: now];
    
    dateComponent.hour = 11; // the default notification time is 8am.
    dateComponent.minute = 0;
    dateComponent.second = 0;
    dateComponent.day = 2;
    
    NSDate *end = [[NSCalendar currentCalendar] dateFromComponents:dateComponent];

    NSInteger days = [AppUtils daysWithinEraFromDate:start toDate:end];
    XCTAssert(days == 1, @"Pass");
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
