//
//  PKPayment+StripeTest.m
//  Stripe
//
//  Created by Ben Guo on 7/6/15.
//  Copyright © 2015 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <PassKit/PassKit.h>
#import "PKPayment+Stripe.h"

@interface PKPayment_StripeTest : XCTestCase

@end

@implementation PKPayment_StripeTest

- (void)testIsSimulated
{
    if (![PKPayment class]) {
        return;
    }
    PKPayment *payment = [PKPayment new];
    PKPaymentToken *paymentToken = [PKPaymentToken new];

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    [paymentToken performSelector:@selector(setTransactionIdentifier:) withObject:@"Simulated Identifier"];
    [payment performSelector:@selector(setToken:) withObject:paymentToken];
#pragma clang diagnostic pop

    XCTAssertTrue([payment isSimulated]);
}

- (void)testSetFakeTransactionIdentifier
{
    if (![PKPayment class]) {
        return;
    }
    PKPayment *payment = [PKPayment new];
    [payment setFakeTransactionIdentifier];
    XCTAssertTrue([payment.token.transactionIdentifier containsString:@"ApplePayStubs~4242424242424242~2000~USD~"]);
}

@end
