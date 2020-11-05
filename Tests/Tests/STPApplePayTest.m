//
//  STPApplePayTest.m
//  Stripe
//
//  Created by Ben Guo on 6/1/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>

@interface STPApplePayTest : XCTestCase

@end

@implementation STPApplePayTest

- (void)testPaymentRequestWithMerchantIdentifierCountryCurrency {
    PKPaymentRequest *paymentRequest = [StripeAPI paymentRequestWithMerchantIdentifier:@"foo" country:@"GB" currency:@"GBP"];
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

    XCTAssertTrue([StripeAPI canSubmitPaymentRequest:request]);
}

- (void)testCanSubmitPaymentRequestIfTotalIsZero {
    PKPaymentRequest *request = [[PKPaymentRequest alloc] init];
    request.merchantIdentifier = @"foo";
    request.paymentSummaryItems = @[[PKPaymentSummaryItem summaryItemWithLabel:@"bar" amount:[NSDecimalNumber decimalNumberWithString:@"0.00"]]];

    // "In versions of iOS prior to version 12.0 and watchOS prior to version 5.0, the amount of the grand total must be greater than zero."
    if (@available(iOS 12, *)) {
        XCTAssertTrue([StripeAPI canSubmitPaymentRequest:request]);
    } else {
        XCTAssertFalse([StripeAPI canSubmitPaymentRequest:request]);
    }
}

- (void)testCanSubmitPaymentRequestReturnsNOIfMerchantIdentifierIsNil {
    PKPaymentRequest *request = [[PKPaymentRequest alloc] init];
    request.paymentSummaryItems = @[[PKPaymentSummaryItem summaryItemWithLabel:@"bar" amount:[NSDecimalNumber decimalNumberWithString:@"1.00"]]];

    XCTAssertFalse([StripeAPI canSubmitPaymentRequest:request]);
}

- (void)testAdditionalPaymentNetwork {
    XCTAssertFalse([[StripeAPI supportedPKPaymentNetworks] containsObject:PKPaymentNetworkJCB]);
    StripeAPI.additionalEnabledApplePayNetworks = @[PKPaymentNetworkJCB];
    XCTAssertTrue([[StripeAPI supportedPKPaymentNetworks] containsObject:PKPaymentNetworkJCB]);
    StripeAPI.additionalEnabledApplePayNetworks = @[];
}

@end
