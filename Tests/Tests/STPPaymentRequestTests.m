//
//  STPPaymentRequestTests.m
//  Stripe
//
//  Created by Ben Guo on 4/19/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "STPPaymentRequest.h"
#import "STPApplePayPaymentMethod.h"

@interface STPPaymentRequestTests : XCTestCase

@end

@implementation STPPaymentRequestTests

- (void)testDecimalAmount_hasDecimal {
    STPPaymentRequest *request = [[STPPaymentRequest alloc] initWithAppleMerchantIdentifier:@"foo" paymentMethod:[STPApplePayPaymentMethod new] amount:1000 currency:@"usd"];

    NSDecimalNumber *decimalNumber = request.decimalAmount;
    XCTAssertEqualObjects(decimalNumber, [NSDecimalNumber decimalNumberWithString:@"10.00"]);
}

- (void)testDecimalAmount_noDecimal {
    STPPaymentRequest *request = [[STPPaymentRequest alloc] initWithAppleMerchantIdentifier:@"foo" paymentMethod:[STPApplePayPaymentMethod new] amount:1000 currency:@"jpy"];

    NSDecimalNumber *decimalNumber = request.decimalAmount;
    XCTAssertEqualObjects(decimalNumber, [NSDecimalNumber decimalNumberWithString:@"1000"]);
}


@end
