//
//  STPIBANValidatorTest.m
//  Stripe
//
//  Created by Ben Guo on 2/15/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "STPIBANValidator.h"

@interface STPIBANValidator ()
+ (NSString *)stringByReplacingLettersWithDigits:(NSString *)string;
@end

@interface STPIBANValidatorTest : XCTestCase

@end

@implementation STPIBANValidatorTest

- (void)testSanitizedIBANForString {
    NSArray *tests = @[
                       @[@"A", @"A"],
                       @[@"a", @"A"],
                       @[@"A0", @"A"],
                       @[@"*A", @"A"],
                       @[@"1234aB", @""],
                       @[@"AB", @"AB"],
                       @[@"ABCDEF", @"AB"],
                       @[@"ABCD1234", @"AB"],
                       @[@"A1234", @"A"],
                       @[@"AB1CD", @"AB1"],
                       @[@"AB12CD", @"AB12CD"],
                       @[@"AB1234CD", @"AB1234CD"],
                       @[@"*AB1234CD", @"AB1234CD"],
                       @[@"AB1234CD!*", @"AB1234CD"],
                       @[@"*AB1234CD!*", @"AB1234CD"],
                       @[@"GB82WEST12345698765432TOOLONG", @"GB82WEST12345698765432"],
                       @[@"ZZ12INVALIDCOUNTRYCODE", @"ZZ12INVALIDCOUNTRYCODE"],
                       ];
    for (NSArray *test in tests) {
        XCTAssertEqualObjects([STPIBANValidator sanitizedIBANForString:test[0]], test[1]);
    }
}

- (void)testStringIsValidPartialIBAN {
    NSArray *tests = @[
                       @[@"A", @YES],
                       @[@"DE", @YES],
                       @[@"FR12ABC", @YES],
                       @[@"ZZ12345", @NO],
                       ];
    for (NSArray *test in tests) {
        XCTAssertEqual([STPIBANValidator stringIsValidPartialIBAN:test[0]], [test[1] boolValue]);
    }
}

- (void)testStringByReplacingLettersWithDigits {
    NSArray *tests = @[
                       @[@"A", @"10"],
                       @[@"1Z", @"135"],
                       @[@"12ABC34", @"1210111234"],
                       @[@"WEST1234", @"321428291234"],
                       ];
    for (NSArray *test in tests) {
        XCTAssertEqualObjects([STPIBANValidator stringByReplacingLettersWithDigits:test[0]], test[1]);
    }
}

- (void)testStringIsValidIBAN {
    NSArray *tests = @[
                       @[@"GB82WEST12345698765432", @YES],
                       @[@"BE68539007547034", @YES],
                       @[@"DE89370400440532013000", @YES],
                       @[@"IE29AIBK93115212345678", @YES],
                       @[@"!AB123", @NO],
                       @[@"123456", @NO],
                       @[@"DK0000000000000000", @NO],
                       @[@"ZZ82WEST12345698765432", @NO],
                       ];
    for (NSArray *test in tests) {
        XCTAssertEqual([STPIBANValidator stringIsValidIBAN:test[0]], [test[1] boolValue]);
    }
}

@end
