//
//  STPPhoneNumberValidatorTest.m
//  Stripe
//
//  Created by Ben Guo on 3/22/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "STPPhoneNumberValidator.h"

static NSString *const kUSCountryCode = @"US";
static NSString *const kUKCountryCode = @"UK";

@interface STPPhoneNumberValidatorTest : XCTestCase

@end

@implementation STPPhoneNumberValidatorTest

- (void)testValidPhoneNumbers {
    XCTAssertTrue([STPPhoneNumberValidator stringIsValidPhoneNumber:@"555-555-5555" forCountryCode:kUSCountryCode]);
    XCTAssertTrue([STPPhoneNumberValidator stringIsValidPhoneNumber:@"5555555555" forCountryCode:kUSCountryCode]);
    XCTAssertTrue([STPPhoneNumberValidator stringIsValidPhoneNumber:@"(555) 555-5555" forCountryCode:kUSCountryCode]);
}

- (void)testInvalidPhoneNumbers {
    XCTAssertFalse([STPPhoneNumberValidator stringIsValidPhoneNumber:@""]);
    XCTAssertFalse([STPPhoneNumberValidator stringIsValidPhoneNumber:@"555-555-555"]);
    XCTAssertFalse([STPPhoneNumberValidator stringIsValidPhoneNumber:@"555-555-A555"]);
    XCTAssertFalse([STPPhoneNumberValidator stringIsValidPhoneNumber:@"55555555555"]);
}

- (void)testFormattedSanitizedPhoneNumberForString {
    XCTAssertEqualObjects([STPPhoneNumberValidator formattedSanitizedPhoneNumberForString:@"55"], @"55");
    XCTAssertEqualObjects([STPPhoneNumberValidator formattedSanitizedPhoneNumberForString:@"555"], @"(555) ");
    XCTAssertEqualObjects([STPPhoneNumberValidator formattedSanitizedPhoneNumberForString:@"55555"], @"(555) 55");
    XCTAssertEqualObjects([STPPhoneNumberValidator formattedSanitizedPhoneNumberForString:@"A-55555"], @"(555) 55");
    XCTAssertEqualObjects([STPPhoneNumberValidator formattedSanitizedPhoneNumberForString:@"5555555"], @"(555) 555-5");
    XCTAssertEqualObjects([STPPhoneNumberValidator formattedSanitizedPhoneNumberForString:@"5555555555"], @"(555) 555-5555");
    XCTAssertEqualObjects([STPPhoneNumberValidator formattedSanitizedPhoneNumberForString:@"5555555555123"], @"(555) 555-5555");
    XCTAssertEqualObjects([STPPhoneNumberValidator formattedSanitizedPhoneNumberForString:@"5555555555123" forCountryCode:kUKCountryCode], 
                          @"5555555555123");
}

- (void)testFormattedRedactedPhoneNumberForString {
    XCTAssertEqualObjects([STPPhoneNumberValidator formattedRedactedPhoneNumberForString:@"+1******1234"], @"+1 (•••) •••-1234");
    XCTAssertEqualObjects([STPPhoneNumberValidator formattedRedactedPhoneNumberForString:@"+86******1234" forCountryCode:kUKCountryCode], @"+86 ••••••1234");
}

@end
