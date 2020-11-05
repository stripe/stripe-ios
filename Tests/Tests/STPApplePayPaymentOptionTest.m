//
//  STPApplePayPaymentOptionTest.m
//  Stripe
//
//  Created by Joey Dong on 7/28/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>



@interface STPApplePayPaymentOptionTest : XCTestCase

@end

@implementation STPApplePayPaymentOptionTest

#pragma mark - STPPaymentOption Tests

- (void)testImage {
    STPApplePayPaymentOption *applePay = [[STPApplePayPaymentOption alloc] init];
    XCTAssert([applePay image]);
}

- (void)testTemplateImage {
    STPApplePayPaymentOption *applePay = [[STPApplePayPaymentOption alloc] init];
    XCTAssert([applePay templateImage]);
}

- (void)testLabel {
    STPApplePayPaymentOption *applePay = [[STPApplePayPaymentOption alloc] init];
    XCTAssertEqualObjects([applePay label], @"Apple Pay");
}

#pragma mark - Equality Tests

- (void)testApplePayEquals {
    STPApplePayPaymentOption *applePay1 = [[STPApplePayPaymentOption alloc] init];
    STPApplePayPaymentOption *applePay2 = [[STPApplePayPaymentOption alloc] init];

    XCTAssertNotEqual(applePay1, applePay2);

    XCTAssertEqualObjects(applePay1, applePay1);
    XCTAssertEqualObjects(applePay1, applePay2);

    XCTAssertEqual(applePay1.hash, applePay1.hash);
    XCTAssertEqual(applePay1.hash, applePay2.hash);
}
@end
