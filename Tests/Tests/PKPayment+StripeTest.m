//
//  PKPayment+StripeTest.m
//  Stripe
//
//  Created by Ben Guo on 7/6/15.
//  Copyright © 2015 Stripe, Inc. All rights reserved.
//

@import XCTest;
@import PassKit;

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

    XCTAssertTrue([payment stp_isSimulated]);
}

- (void)testTestTransactionIdentifier
{
    if (![PKPayment class]) {
        return;
    }
    NSString *identifier = [PKPayment stp_testTransactionIdentifier];
    XCTAssertTrue([identifier containsString:@"ApplePayStubs~4242424242424242~0~USD~"]);
}

@end
