//
//  STPConfirmCardOptionsTest.m
//  StripeiOS Tests
//
//  Created by Cameron Sabol on 1/10/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>


@interface STPConfirmCardOptionsTest : XCTestCase

@end

@implementation STPConfirmCardOptionsTest

- (void)testCVC {
    STPConfirmCardOptions *cardOptions = [[STPConfirmCardOptions alloc] init];

    XCTAssertNil(cardOptions.cvc, @"Initial/default value should be nil.");
    XCTAssertNil(cardOptions.network, @"Initial/default value should be nil.");

    cardOptions.cvc = @"123";
    XCTAssertEqualObjects(cardOptions.cvc, @"123", @"cvc should be set to '123'.");
    cardOptions.network = @"visa";
    XCTAssertEqualObjects(cardOptions.network, @"visa", @"network should be set to 'visa'.");
}

- (void)testEncoding {
    NSDictionary *propertyMap = [STPConfirmCardOptions propertyNamesToFormFieldNamesMapping];
    NSDictionary *expected = @{@"cvc": @"cvc", @"network": @"network"};
    XCTAssertEqualObjects(propertyMap, expected, @"Unexpected property to field name mapping.");
}

@end
