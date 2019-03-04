//
//  STPApplePayPaymentOptionTest.m
//  Stripe
//
//  Created by Joey Dong on 7/28/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "STPApplePay.h"

@interface STPApplePayPaymentOptionTest : XCTestCase

@end

@implementation STPApplePayPaymentOptionTest

#pragma mark - STPPaymentOption Tests

- (void)testImage {
    STPApplePay *applePay = [[STPApplePay alloc] init];
    XCTAssert([applePay image]);
}

- (void)testTemplateImage {
    STPApplePay *applePay = [[STPApplePay alloc] init];
    XCTAssert([applePay templateImage]);
}

- (void)testLabel {
    STPApplePay *applePay = [[STPApplePay alloc] init];
    XCTAssertEqualObjects([applePay label], @"Apple Pay");
}

#pragma mark - Equality Tests

- (void)testApplePayEquals {
    STPApplePay *applePay1 = [[STPApplePay alloc] init];
    STPApplePay *applePay2 = [[STPApplePay alloc] init];

    XCTAssertNotEqual(applePay1, applePay2);

    XCTAssertEqualObjects(applePay1, applePay1);
    XCTAssertEqualObjects(applePay1, applePay2);

    XCTAssertEqual(applePay1.hash, applePay1.hash);
    XCTAssertEqual(applePay1.hash, applePay2.hash);
}
@end
