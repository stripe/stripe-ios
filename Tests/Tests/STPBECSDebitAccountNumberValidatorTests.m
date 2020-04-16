//
//  STPBECSDebitAccountNumberValidatorTests.m
//  StripeiOS Tests
//
//  Created by Cameron Sabol on 3/13/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "STPBECSDebitAccountNumberValidator.h"

@interface STPBECSDebitAccountNumberValidatorTests : XCTestCase

@end

@implementation STPBECSDebitAccountNumberValidatorTests

- (void)testValidationStateForText {
    NSArray<NSDictionary *> *tests = @[

        // empty input
        @{
            @"input": @"",
            @"bsb": @"",
            @"editing": @(NO),
            @"expected": @(STPTextValidationStateEmpty),
        },

        @{
            @"input": @"",
            @"bsb": @"0",
            @"editing": @(NO),
            @"expected": @(STPTextValidationStateEmpty),
        },

        @{
            @"input": @"",
            @"editing": @(NO),
            @"expected": @(STPTextValidationStateEmpty),
        },

        @{
            @"input": @"",
            @"bsb": @"00",
            @"editing": @(NO),
            @"expected": @(STPTextValidationStateEmpty),
        },

        // incomplete input
        @{
            @"input": @"1",
            @"bsb": @"",
            @"editing": @(NO),
            @"expected": @(STPTextValidationStateIncomplete),
        },

        @{
            @"input": @"1",
            @"bsb": @"0",
            @"editing": @(NO),
            @"expected": @(STPTextValidationStateIncomplete),
        },

        @{
            @"input": @"1",
            @"bsb": @"00",
            @"editing": @(NO),
            @"expected": @(STPTextValidationStateIncomplete),
        },

        @{
            @"input": @"1",
            @"editing": @(NO),
            @"expected": @(STPTextValidationStateIncomplete),
        },

        @{
            @"input": @"12345",
            @"bsb": @"06",
            @"editing": @(NO),
            @"expected": @(STPTextValidationStateIncomplete),
        },

        // incomplete input (editing)
        @{
            @"input": @"1",
            @"bsb": @"",
            @"editing": @(YES),
            @"expected": @(STPTextValidationStateIncomplete),
        },

        @{
            @"input": @"1",
            @"bsb": @"0",
            @"editing": @(YES),
            @"expected": @(STPTextValidationStateIncomplete),
        },

        @{
            @"input": @"1",
            @"bsb": @"00",
            @"editing": @(YES),
            @"expected": @(STPTextValidationStateIncomplete),
        },

        @{
            @"input": @"1",
            @"editing": @(YES),
            @"expected": @(STPTextValidationStateIncomplete),
        },

        @{
            @"input": @"12345",
            @"bsb": @"06",
            @"editing": @(YES),
            @"expected": @(STPTextValidationStateIncomplete),
        },

        @{
            @"input": @"12345678",
            @"bsb": @"",
            @"editing": @(YES),
            @"expected": @(STPTextValidationStateIncomplete),
        },

        // complete
        @{
            @"input": @"12345",
            @"bsb": @"",
            @"editing": @(NO),
            @"expected": @(STPTextValidationStateComplete),
        },

        @{
            @"input": @"123456",
            @"bsb": @"",
            @"editing": @(NO),
            @"expected": @(STPTextValidationStateComplete),
        },

        @{
            @"input": @"1234567",
            @"bsb": @"",
            @"editing": @(NO),
            @"expected": @(STPTextValidationStateComplete),
        },

        @{
            @"input": @"12345678",
            @"bsb": @"",
            @"editing": @(NO),
            @"expected": @(STPTextValidationStateComplete),
        },

        @{
            @"input": @"123456789",
            @"bsb": @"",
            @"editing": @(NO),
            @"expected": @(STPTextValidationStateComplete),
        },

        // complete (editing)
        @{
            @"input": @"123456789",
            @"bsb": @"",
            @"editing": @(YES),
            @"expected": @(STPTextValidationStateComplete),
        },

        // invalid
        @{
            @"input": @"12345678910",
            @"bsb": @"",
            @"editing": @(NO),
            @"expected": @(STPTextValidationStateInvalid),
        },

        // invalid (editing)
        @{
            @"input": @"12345678910",
            @"bsb": @"",
            @"editing": @(YES),
            @"expected": @(STPTextValidationStateInvalid),
        },

    ];

    for (NSDictionary *test in tests) {
        NSString *input = test[@"input"];
        NSString *bsb = test[@"bsb"];
        BOOL editing = [test[@"editing"] boolValue];
        STPTextValidationState expected = (STPTextValidationState)[test[@"expected"] unsignedIntegerValue];

        XCTAssertEqual([STPBECSDebitAccountNumberValidator validationStateForText:input withBSBNumber:bsb completeOnMaxLengthOnly:editing], expected, @"%@ not marked as %@ while editing %d with bsb %@", input, @(expected), editing, bsb);
    }
}

- (void)testFormattedSantizedTextFromString {
    NSArray<NSDictionary *> *tests = @[
        @{
            @"input": @"",
            @"bsb": @"00",
            @"expected": @"",
        },

        @{
            @"input": @"1",
            @"bsb": @"00",
            @"expected": @"1",
        },

        @{
            @"input": @"--111111--",
            @"bsb": @"00",
            @"expected": @"111111",
        },

        @{
            @"input": @"12345678910",
            @"bsb": @"00",
            @"expected": @"123456789",
        },

        @{
            @"input": @"",
            @"bsb": @"06",
            @"expected": @"",
        },

        @{
            @"input": @"1",
            @"bsb": @"06",
            @"expected": @"1",
        },

        @{
            @"input": @"--111111--",
            @"bsb": @"06",
            @"expected": @"111111",
        },

        @{
            @"input": @"12345678910",
            @"bsb": @"06",
            @"expected": @"123456789",
        },

    ];

    for (NSDictionary *test in tests) {
        NSString *input = test[@"input"];
        NSString *bsb = test[@"bsb"];
        NSString *expected = test[@"expected"];
        XCTAssertEqualObjects([STPBECSDebitAccountNumberValidator formattedSantizedTextFromString:input withBSBNumber:bsb], expected, @"%@ not formatted to %@ for bsb %@", input, expected, bsb);
    }
}

@end
