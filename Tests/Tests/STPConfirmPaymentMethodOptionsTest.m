//
//  STPConfirmPaymentMethodOptionsTest.m
//  StripeiOS Tests
//
//  Created by Cameron Sabol on 1/10/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>


@interface STPConfirmPaymentMethodOptionsTest : XCTestCase

@end

@implementation STPConfirmPaymentMethodOptionsTest

- (void)testCardOptions {
    STPConfirmPaymentMethodOptions *paymentMethodOptions = [[STPConfirmPaymentMethodOptions alloc] init];

    XCTAssertNil(paymentMethodOptions.cardOptions, @"Default card value should be nil.");

    STPConfirmCardOptions *cardOptions =  [[STPConfirmCardOptions alloc] init];
    paymentMethodOptions.cardOptions =  cardOptions;
    XCTAssertEqual(paymentMethodOptions.cardOptions, cardOptions, @"Should hold reference to set cardOptions.");
}

- (void)testFormEncoding {
    NSDictionary *propertyToFieldMap = [STPConfirmPaymentMethodOptions propertyNamesToFormFieldNamesMapping];
    NSDictionary *expected = @{@"cardOptions": @"card", @"alipayOptions": @"alipay"};

    XCTAssertEqualObjects(propertyToFieldMap, expected, @"Unexpected property to field name mapping.");
}

@end
