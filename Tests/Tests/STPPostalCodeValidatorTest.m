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

- (void)testValidPostalCodes {
    NSArray *numbers = @[
                          @"10002",
                          @"10002-1234",
                          @"21218",
                          ];
    for (NSString *number in numbers) {
        XCTAssertTrue([STPPostalCodeValidator stringIsValidPostalCode:number]);
    }
}

- (void)testInvalidPostalCodes {
     NSArray *numbers = @[
                          @"",
                          @"$$$$$",
                          @"foo",
                          ];
    for (NSString *number in numbers) {
        XCTAssertFalse([STPPostalCodeValidator stringIsValidPostalCode:number]);
    }   
}

@end
