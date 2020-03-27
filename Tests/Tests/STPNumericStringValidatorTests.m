//
//  STPNumericStringValidatorTests.m
//  StripeiOS Tests
//
//  Created by Cameron Sabol on 3/13/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "STPNumericStringValidator.h"

@interface STPNumericStringValidatorTests : XCTestCase

@end

@implementation STPNumericStringValidatorTests

- (void)testNumberSanitization {
    NSArray *tests = @[
        @[@"4242424242424242", @"4242424242424242"],
        @[@"XXXXXX", @""],
        @[@"424242424242424X", @"424242424242424"],
        @[@"X4242", @"4242"],
        @[@"4242 4242 4242 4242", @"4242424242424242"],
        @[@"123-456-", @"123456"],
    ];
    for (NSArray *test in tests) {
        XCTAssertEqualObjects([STPNumericStringValidator sanitizedNumericStringForString:test[0]], test[1], @"%@ not sanitized to %@", test[0], test[1]);
    }
}

- (void)testIsStringNumeric {
    NSArray *tests = @[
        @[@"4242424242424242", @(YES)],
        @[@"XXXXXX", @(NO)],
        @[@"424242424242424X", @(NO)],
        @[@"X4242", @(NO)],
        @[@"4242 4242 4242 4242",@(NO)],
        @[@"123-456-", @(NO)],
        @[@"    1", @(NO)],
        @[@"", @(YES)],
    ];
    for (NSArray *test in tests) {
        XCTAssertEqual([STPNumericStringValidator isStringNumeric:test[0]], [test[1] boolValue], @"%@ not marked as numeric %@", test[0], test[1]);
    }
}

@end
