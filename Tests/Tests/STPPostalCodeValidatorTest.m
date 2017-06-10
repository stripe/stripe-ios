//
//  STPPostalCodeValidatorTest.m
//  Stripe
//
//  Created by Ben Guo on 4/14/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "STPPostalCodeValidator.h"

@interface STPPostalCodeValidatorTest : XCTestCase

@end

@implementation STPPostalCodeValidatorTest

- (void)testValidUSPostalCodes {
    NSArray *codes = @[
                       @"10002",
                       @"10002-1234",
                       @"100021234",
                       @"21218",
                       ];
    for (NSString *code in codes) {
        XCTAssertEqual([STPPostalCodeValidator validationStateForPostalCode:code
                                                                countryCode:@"US"],
                       STPCardValidationStateValid,
                       @"Valid US postal code test failed for code: %@", code);
    }
}

- (void)testInvalidUSPostalCodes {
    NSArray *codes = @[
                       @"100A03",
                       @"12345-12345",
                       @"1234512345",
                       @"$$$$$",
                       @"foo",
                       ];
    for (NSString *code in codes) {
        XCTAssertEqual([STPPostalCodeValidator validationStateForPostalCode:code
                                                                countryCode:@"US"],
                       STPCardValidationStateInvalid,
                       @"Invalid US postal code test failed for code: %@", code);
    }   
}

- (void)testIncompleteUSPostalCodes {
    NSArray *codes = @[
                       @"",
                       @"123",
                       @"12345-",
                       @"12345-12",
                       ];
    for (NSString *code in codes) {
        XCTAssertEqual([STPPostalCodeValidator validationStateForPostalCode:code
                                                                countryCode:@"US"],
                       STPCardValidationStateIncomplete,
                       @"Incomplete US postal code test failed for code: %@", code);
    }
}

- (void)testValidGenericPostalCodes {
    NSArray *codes = @[
                       @"ABC10002",
                       @"10002-ABCD",
                       @"ABCDE",
                       ];
    for (NSString *code in codes) {
        XCTAssertEqual([STPPostalCodeValidator validationStateForPostalCode:code
                                                                countryCode:@"UK"],
                       STPCardValidationStateValid,
                       @"Valid generic postal code test failed for code: %@", code);
    }
}

- (void)testIncompleteGenericPostalCodes {
    NSArray *codes = @[
                       @"",
                       ];
    for (NSString *code in codes) {
        XCTAssertEqual([STPPostalCodeValidator validationStateForPostalCode:code
                                                                countryCode:@"UK"],
                       STPCardValidationStateIncomplete,
                       @"Incomplete generic postal code test failed for code: %@", code);
    }   
}

@end
