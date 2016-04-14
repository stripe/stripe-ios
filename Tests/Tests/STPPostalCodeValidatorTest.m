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

- (void)testValidPhoneNumbers {
    NSArray *numbers = @[
                          @"888-555-1212",
                          @"8885551212",
                          @"(888) 555-1212",
                          ];
    for (NSString *number in numbers) {
        XCTAssertTrue([STPPostalCodeValidator stringIsValidPostalCode:number]);
    }
}

- (void)testInvalidPhoneNumbers {
     NSArray *numbers = @[
                          @"888-555-121",
                          @"123",
                          @"foo",
                          ];
    for (NSString *number in numbers) {
        XCTAssertFalse([STPPostalCodeValidator stringIsValidPostalCode:number]);
    }   
}

@end
