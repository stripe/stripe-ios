//
//  STPPhoneNumberValidatorTest.m
//  Stripe
//
//  Created by Ben Guo on 3/22/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "STPPhoneNumberValidator.h"

@interface STPPhoneNumberValidatorTest : XCTestCase

@end

@implementation STPPhoneNumberValidatorTest

- (void)testValidPhoneNumbers {
    XCTAssertTrue([STPPhoneNumberValidator stringIsValidPhoneNumber:@"555-555-5555"]);
    XCTAssertTrue([STPPhoneNumberValidator stringIsValidPhoneNumber:@"5555555555"]);
    XCTAssertTrue([STPPhoneNumberValidator stringIsValidPhoneNumber:@"(555) 555-5555"]);
}

- (void)testInvalidPhoneNumbers {
    XCTAssertFalse([STPPhoneNumberValidator stringIsValidPhoneNumber:@""]);
    XCTAssertFalse([STPPhoneNumberValidator stringIsValidPhoneNumber:@"555-555-555"]);
    XCTAssertFalse([STPPhoneNumberValidator stringIsValidPhoneNumber:@"555-555-A555"]);
    XCTAssertFalse([STPPhoneNumberValidator stringIsValidPhoneNumber:@"55555555555"]);
}

- (void)testFormattedPhoneNumberForString {
    XCTAssertEqualObjects([STPPhoneNumberValidator formattedPhoneNumberForString:@"55"], @"55");
    XCTAssertEqualObjects([STPPhoneNumberValidator formattedPhoneNumberForString:@"555"], @"(555) ");
    XCTAssertEqualObjects([STPPhoneNumberValidator formattedPhoneNumberForString:@"55555"], @"(555) 55");
    XCTAssertEqualObjects([STPPhoneNumberValidator formattedPhoneNumberForString:@"A-55555"], @"(555) 55");
    XCTAssertEqualObjects([STPPhoneNumberValidator formattedPhoneNumberForString:@"5555555"], @"(555) 555-5");
    XCTAssertEqualObjects([STPPhoneNumberValidator formattedPhoneNumberForString:@"5555555555"], @"(555) 555-5555");
    XCTAssertEqualObjects([STPPhoneNumberValidator formattedPhoneNumberForString:@"5555555555123"], @"(555) 555-5555");
}

@end
