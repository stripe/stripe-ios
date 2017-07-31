//
//  STPApplePayPaymentMethodTest.m
//  Stripe
//
//  Created by Joey Dong on 7/28/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "STPApplePayPaymentMethod.h"

@interface STPApplePayPaymentMethodTest : XCTestCase

@end

@implementation STPApplePayPaymentMethodTest

#pragma mark - STPPaymentMethod Tests

- (void)testImage {
    STPApplePayPaymentMethod *applePay = [[STPApplePayPaymentMethod alloc] init];
    XCTAssert([applePay image]);
}

- (void)testTemplateImage {
    STPApplePayPaymentMethod *applePay = [[STPApplePayPaymentMethod alloc] init];
    XCTAssert([applePay templateImage]);
}

- (void)testLabel {
    STPApplePayPaymentMethod *applePay = [[STPApplePayPaymentMethod alloc] init];
    XCTAssertEqualObjects([applePay label], @"Apple Pay");
}

#pragma mark - Equality Tests

- (void)testApplePayEquals {
    STPApplePayPaymentMethod *applePay1 = [[STPApplePayPaymentMethod alloc] init];
    STPApplePayPaymentMethod *applePay2 = [[STPApplePayPaymentMethod alloc] init];

    XCTAssertNotEqual(applePay1, applePay2);

    XCTAssertEqualObjects(applePay1, applePay1);
    XCTAssertEqualObjects(applePay1, applePay2);

    XCTAssertEqual(applePay1.hash, applePay1.hash);
    XCTAssertEqual(applePay1.hash, applePay2.hash);
}
@end
