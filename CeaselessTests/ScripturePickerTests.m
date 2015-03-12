//
//  ScripturePickerTests.m
//  Ceaseless
//
//  Created by Christopher Lim on 3/12/15.
//  Copyright (c) 2015 Christopher Lim. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "ScripturePicker.h"

@interface ScripturePickerTests : XCTestCase
    @property (nonatomic) ScripturePicker *picker;
@end

@implementation ScripturePickerTests

- (void)setUp {
    [super setUp];
    _picker = [[ScripturePicker alloc] init];
    // TODO we could clean up the queue
}

- (void)tearDown {
    // TODO we could restore the queue
    [super tearDown];
}

- (void)testPopScriptureQueue {
    ScriptureQueue *sq = [_picker popScriptureQueue];
    XCTAssertNotNil(sq, @"Pass");
}

@end
