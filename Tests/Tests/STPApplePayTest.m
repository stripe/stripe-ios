//
//  STPApplePayTest.m
//  Stripe
//
//  Created by Ben Guo on 6/1/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "STPAPIClient+Private.h"

@interface STPApplePayTest : XCTestCase

@end

@implementation STPApplePayTest

- (void)testPaymentRequestWithMerchantIdentifierCountryCurrency {
    PKPaymentRequest *paymentRequest = [Stripe paymentRequestWithMerchantIdentifier:@"foo" country:@"GB" currency:@"GBP"];
    XCTAssertEqualObjects(paymentRequest.merchantIdentifier, @"foo");
    NSSet *expectedNetworks = [NSSet setWithArray:@[PKPaymentNetworkAmex, PKPaymentNetworkMasterCard, PKPaymentNetworkVisa, PKPaymentNetworkDiscover]];
    XCTAssertEqualObjects([NSSet setWithArray:paymentRequest.supportedNetworks], expectedNetworks);
    XCTAssertEqual(paymentRequest.merchantCapabilities, PKMerchantCapability3DS);
    XCTAssertEqualObjects(paymentRequest.countryCode, @"GB");
    XCTAssertEqualObjects(paymentRequest.currencyCode, @"GBP");
}

- (void)testCanSubmitPaymentRequestReturnsYES {
    PKPaymentRequest *request = [[PKPaymentRequest alloc] init];
    request.merchantIdentifier = @"foo";
    request.paymentSummaryItems = @[[PKPaymentSummaryItem summaryItemWithLabel:@"bar" amount:[NSDecimalNumber decimalNumberWithString:@"1.00"]]];

    XCTAssertTrue([Stripe canSubmitPaymentRequest:request]);
}

- (void)testCanSubmitPaymentRequestReturnsNOIfTotalIsZero {
    PKPaymentRequest *request = [[PKPaymentRequest alloc] init];
    request.merchantIdentifier = @"foo";
    request.paymentSummaryItems = @[[PKPaymentSummaryItem summaryItemWithLabel:@"bar" amount:[NSDecimalNumber decimalNumberWithString:@"0.00"]]];

    XCTAssertFalse([Stripe canSubmitPaymentRequest:request]);
}

- (void)testCanSubmitPaymentRequestReturnsNOIfMerchantIdentifierIsNil {
    PKPaymentRequest *request = [[PKPaymentRequest alloc] init];
    request.paymentSummaryItems = @[[PKPaymentSummaryItem summaryItemWithLabel:@"bar" amount:[NSDecimalNumber decimalNumberWithString:@"1.00"]]];

    XCTAssertFalse([Stripe canSubmitPaymentRequest:request]);
}

- (void)testAdditionalPaymentNetwork {
    if (&PKPaymentNetworkJCB == NULL) {
        XCTAssertTrue([Stripe supportedPKPaymentNetworks].count > 0); // Sanity check this doesn't crash
        return;
    }
    XCTAssertFalse([[Stripe supportedPKPaymentNetworks] containsObject:PKPaymentNetworkJCB]);
    Stripe.additionalEnabledApplePayNetworks = @[PKPaymentNetworkJCB];
    XCTAssertTrue([[Stripe supportedPKPaymentNetworks] containsObject:PKPaymentNetworkJCB]);
    Stripe.additionalEnabledApplePayNetworks = @[];
}

@end
