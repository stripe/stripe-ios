//
//  Stripe+ApplePayTest.m
//  Stripe
//
//  Created by Ben Guo on 5/30/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <PassKit/PassKit.h>
#import <OCMock/OCMock.h>
#import "STPAPIClient.h"

@interface Stripe_ApplePayTest : XCTestCase

@end

@implementation Stripe_ApplePayTest

- (void)testCanSubmitPaymentRequest_valid {
    PKPaymentRequest *request = [[PKPaymentRequest alloc] init];
    request.merchantIdentifier = @"foo";
    request.paymentSummaryItems = @[[PKPaymentSummaryItem summaryItemWithLabel:@"bar" amount:[NSDecimalNumber decimalNumberWithString:@"1.00"]]];

    XCTAssertTrue([Stripe canSubmitPaymentRequest:request]);
}

- (void)testCanSubmitPaymentRequest_zeroTotal {
    PKPaymentRequest *request = [[PKPaymentRequest alloc] init];
    request.merchantIdentifier = @"foo";
    request.paymentSummaryItems = @[[PKPaymentSummaryItem summaryItemWithLabel:@"bar" amount:[NSDecimalNumber decimalNumberWithString:@"0.00"]]];

    XCTAssertFalse([Stripe canSubmitPaymentRequest:request]);
}

- (void)testCanSubmitPaymentRequest_nilMerchantIdentifier {
    PKPaymentRequest *request = [[PKPaymentRequest alloc] init];
    request.paymentSummaryItems = @[[PKPaymentSummaryItem summaryItemWithLabel:@"bar" amount:[NSDecimalNumber decimalNumberWithString:@"1.00"]]];

    XCTAssertFalse([Stripe canSubmitPaymentRequest:request]);
}

- (void)testSupportedPKPaymentNetworksForCountry_US {
    NSSet<NSSet *> *networks = [NSSet setWithArray:[Stripe supportedPaymentNetworksForCountry:@"US"]];
    NSSet<NSSet *> *expectedNetworks = [NSSet setWithArray:@[
                                                     PKPaymentNetworkAmex,
                                                     PKPaymentNetworkMasterCard,
                                                     PKPaymentNetworkVisa,
                                                     PKPaymentNetworkDiscover,
                                                     ]];
    XCTAssertEqualObjects(networks, expectedNetworks);
}

- (void)testSupportedPKPaymentNetworksForCountry_notUS {
    NSSet<NSSet *> *networks = [NSSet setWithArray:[Stripe supportedPaymentNetworksForCountry:@"GB"]];
    NSSet<NSSet *> *expectedNetworks = [NSSet setWithArray:@[
                                                     PKPaymentNetworkAmex,
                                                     PKPaymentNetworkMasterCard,
                                                     PKPaymentNetworkVisa,
                                                     ]];
    XCTAssertEqualObjects(networks, expectedNetworks);
}

- (void)testPaymentRequestWithMerchantIdentifier {
    PKPaymentRequest *paymentRequest = [Stripe paymentRequestWithMerchantIdentifier:@"foo"];
    XCTAssertEqualObjects(paymentRequest.merchantIdentifier, @"foo");
    XCTAssertEqualObjects(paymentRequest.supportedNetworks, [Stripe supportedPaymentNetworksForCountry:@"US"]);
    XCTAssertEqual(paymentRequest.merchantCapabilities, PKMerchantCapability3DS);
    XCTAssertEqualObjects(paymentRequest.countryCode, @"US");
    XCTAssertEqualObjects(paymentRequest.currencyCode, @"USD");
}

- (void)testPaymentRequestWithMerchantIdentifierCountry {
    PKPaymentRequest *paymentRequest = [Stripe paymentRequestWithMerchantIdentifier:@"foo" country:@"GB"];
    XCTAssertEqualObjects(paymentRequest.merchantIdentifier, @"foo");
    XCTAssertEqualObjects(paymentRequest.supportedNetworks, [Stripe supportedPaymentNetworksForCountry:@"GB"]);
    XCTAssertEqual(paymentRequest.merchantCapabilities, PKMerchantCapability3DS);
    XCTAssertEqualObjects(paymentRequest.countryCode, @"GB");
    XCTAssertEqualObjects(paymentRequest.currencyCode, @"USD");
}

@end
