//
//  STPBSBNumberValidatorTests.m
//  StripeiOS Tests
//
//  Created by Cameron Sabol on 3/13/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "STPBSBNumberValidator.h"

@interface STPBSBNumberValidatorTests : XCTestCase

@end

@implementation STPBSBNumberValidatorTests

- (void)testValidationStateForText {
    NSArray<NSArray *> *tests = @[
        @[@"", @(STPTextValidationStateEmpty)],
        @[@"1", @(STPTextValidationStateIncomplete)],
        @[@"11", @(STPTextValidationStateIncomplete)],
        @[@"00", @(STPTextValidationStateInvalid)],
        @[@"111111", @(STPTextValidationStateComplete)],
        @[@"111-111", @(STPTextValidationStateComplete)],
        @[@"--111-111--", @(STPTextValidationStateComplete)],
        @[@"1234567", @(STPTextValidationStateInvalid)],
    ];

    for (NSArray *test in tests) {
        XCTAssertEqual([STPBSBNumberValidator validationStateForText:test[0]], (STPTextValidationState)[test[1] unsignedIntegerValue], @"%@ doesn't have validation state %@", test[0], test[1]);
    }
}

- (void)testFormattedSantizedTextFromString {
    NSArray<NSArray *> *tests = @[
        @[@"", @""],
        @[@"1", @"1"],
        @[@"11", @"11"],
        @[@"111", @"111-"],
        @[@"111111", @"111-111"],
        @[@"--111111--", @"111-111"],
        @[@"1234567",@"123-456"],
    ];

    for (NSArray *test in tests) {
        XCTAssertEqualObjects([STPBSBNumberValidator formattedSantizedTextFromString:test[0]], test[1], @"%@ not formatted to %@", test[0], test[1]);
    }
}

- (void)testIdentityForText {
    NSArray<NSArray *> *tests = @[
        @[@"", [NSNull null]],
        @[@"9", [NSNull null]],
        @[@"94", [NSNull null]],
        @[@"941", @"Delphi Bank (division of Bendigo and Adelaide Bank)"],
        @[@"942", @"Bank of Sydney"],
        @[@"942942", @"Bank of Sydney"],
        @[@"40", @"Commonwealth Bank of Australia"],
        @[@"942-942", @"Bank of Sydney"],
        @[@"942942111", @"Bank of Sydney"],
    ];

    for (NSArray *test in tests) {
        if ([test[1] isEqual:[NSNull null]]) {
            XCTAssertNil([STPBSBNumberValidator identityForText:test[0]], @"%@ has non-nil identity", test[0]);
        } else {
            XCTAssertEqualObjects([STPBSBNumberValidator identityForText:test[0]], test[1], @"%@ doesn't have identity %@", test[0], test[1]);
        }
    }
}

- (void)testIconForText {
    UIImage *defaultIcon = [STPBSBNumberValidator iconForText:nil];
    XCTAssertNotNil(defaultIcon, @"Nil default icon");

    XCTAssertEqualObjects(defaultIcon, [STPBSBNumberValidator iconForText:@"00"], @"Invalid ID icon doesn't match default");

    UIImage *bankIcon = [STPBSBNumberValidator iconForText:@"11"];
    XCTAssertNotNil(bankIcon, @"Nil icon for bank `11`");
    XCTAssertFalse([defaultIcon isEqual:bankIcon], @"Icon for `11` is same as default");

    XCTAssertEqualObjects(bankIcon, [STPBSBNumberValidator iconForText:@"111-111"], @"Icon for `11` not equal to icon for `111-111`");
}


@end
