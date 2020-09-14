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
    XCTAssertEqualObjects(paymentRequest.requiredBillingContactFields, [NSSet setWithArray:@[PKContactFieldPostalAddress]]);
}

- (void)testCanSubmitPaymentRequestReturnsYES {
    PKPaymentRequest *request = [[PKPaymentRequest alloc] init];
    request.merchantIdentifier = @"foo";
    request.paymentSummaryItems = @[[PKPaymentSummaryItem summaryItemWithLabel:@"bar" amount:[NSDecimalNumber decimalNumberWithString:@"1.00"]]];

    XCTAssertTrue([Stripe canSubmitPaymentRequest:request]);
}

- (void)testCanSubmitPaymentRequestIfTotalIsZero {
    PKPaymentRequest *request = [[PKPaymentRequest alloc] init];
    request.merchantIdentifier = @"foo";
    request.paymentSummaryItems = @[[PKPaymentSummaryItem summaryItemWithLabel:@"bar" amount:[NSDecimalNumber decimalNumberWithString:@"0.00"]]];

    // "In versions of iOS prior to version 12.0 and watchOS prior to version 5.0, the amount of the grand total must be greater than zero."
    if (@available(iOS 12, *)) {
        XCTAssertTrue([Stripe canSubmitPaymentRequest:request]);
    } else {
        XCTAssertFalse([Stripe canSubmitPaymentRequest:request]);
    }
}

- (void)testCanSubmitPaymentRequestReturnsNOIfMerchantIdentifierIsNil {
    PKPaymentRequest *request = [[PKPaymentRequest alloc] init];
    request.paymentSummaryItems = @[[PKPaymentSummaryItem summaryItemWithLabel:@"bar" amount:[NSDecimalNumber decimalNumberWithString:@"1.00"]]];

    XCTAssertFalse([Stripe canSubmitPaymentRequest:request]);
}

- (void)testAdditionalPaymentNetwork {
    XCTAssertFalse([[Stripe supportedPKPaymentNetworks] containsObject:PKPaymentNetworkJCB]);
    Stripe.additionalEnabledApplePayNetworks = @[PKPaymentNetworkJCB];
    XCTAssertTrue([[Stripe supportedPKPaymentNetworks] containsObject:PKPaymentNetworkJCB]);
    Stripe.additionalEnabledApplePayNetworks = @[];
}

@end
