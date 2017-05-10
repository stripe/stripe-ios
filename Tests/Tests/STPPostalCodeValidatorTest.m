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

- (void)testValidNumericPostalCodes {
    NSArray *codes = @[
                       @"10002",
                       @"10002-1234",
                       @"21218",
                       ];
    for (NSString *code in codes) {
        XCTAssertTrue([STPPostalCodeValidator stringIsValidPostalCode:code
                                                                 type:STPCountryPostalCodeTypeNumericOnly]);
    }
}

- (void)testInvalidNumericPostalCodes {
    NSArray *codes = @[
                       @"",
                       @"$$$$$",
                       @"foo",
                       ];
    for (NSString *code in codes) {
        XCTAssertFalse([STPPostalCodeValidator stringIsValidPostalCode:code
                                                                  type:STPCountryPostalCodeTypeNumericOnly]);
    }   
}

- (void)testValidAlphanumericPostalCodes {
    NSArray *codes = @[
                       @"ABC10002",
                       @"10002-ABCD",
                       @"ABCDE",
                       ];
    for (NSString *code in codes) {
        XCTAssertTrue([STPPostalCodeValidator stringIsValidPostalCode:code
                                                                 type:STPCountryPostalCodeTypeAlphanumeric]);
    }
}

- (void)testInvalidAlphanumericPostalCodes {
    NSArray *codes = @[
                       @"",
                       ];
    for (NSString *code in codes) {
        XCTAssertFalse([STPPostalCodeValidator stringIsValidPostalCode:code
                                                                  type:STPCountryPostalCodeTypeAlphanumeric]);
    }   
}

@end
