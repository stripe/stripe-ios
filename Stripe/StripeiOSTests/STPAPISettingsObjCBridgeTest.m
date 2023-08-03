//
//  STPObjcBridgeTest.m
//  StripeiOS Tests
//
//  Created by David Estes on 9/21/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

@import Stripe;
@import XCTest;
@import PassKit;
#import "STPNetworkStubbingTestCase.h"
#import "STPTestingAPIClient.h"
#import "STPFixtures.h"

@interface StripeAPIBridgeTest : XCTestCase

@end

@implementation StripeAPIBridgeTest

- (void)testStripeAPIBridge {
    NSString *testKey = @"pk_test_123";
    StripeAPI.defaultPublishableKey = testKey;
    XCTAssertEqualObjects(StripeAPI.defaultPublishableKey, testKey);
    StripeAPI.defaultPublishableKey = nil;
    
    StripeAPI.advancedFraudSignalsEnabled = NO;
    XCTAssertFalse(StripeAPI.advancedFraudSignalsEnabled);
    StripeAPI.advancedFraudSignalsEnabled = YES;
    
    
    StripeAPI.maxRetries = 2;
    XCTAssertEqual(StripeAPI.maxRetries, 2);
    StripeAPI.maxRetries = 3;
    
    // Check that this at least doesn't crash
    [StripeAPI handleStripeURLCallbackWithURL:[NSURL URLWithString:@"https://example.com"]];
    
    StripeAPI.jcbPaymentNetworkSupported = YES;
    XCTAssertTrue(StripeAPI.jcbPaymentNetworkSupported);
    StripeAPI.jcbPaymentNetworkSupported = NO;

    StripeAPI.additionalEnabledApplePayNetworks = @[PKPaymentNetworkJCB];
    XCTAssertTrue([StripeAPI.additionalEnabledApplePayNetworks containsObject:PKPaymentNetworkJCB]);
    StripeAPI.additionalEnabledApplePayNetworks = @[];
    
    PKPaymentRequest *request = [StripeAPI paymentRequestWithMerchantIdentifier:@"test" country:@"US" currency:@"USD"];
    request.paymentSummaryItems = @[[PKPaymentSummaryItem summaryItemWithLabel:@"bar" amount:[NSDecimalNumber decimalNumberWithString:@"1.00"]]];
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Wdeprecated"
    PKPaymentRequest *request2 = [StripeAPI paymentRequestWithMerchantIdentifier:@"test"];
    request2.paymentSummaryItems = @[[PKPaymentSummaryItem summaryItemWithLabel:@"bar" amount:[NSDecimalNumber decimalNumberWithString:@"1.00"]]];
    #pragma clang diagnostic pop
    
    XCTAssertTrue([StripeAPI canSubmitPaymentRequest:request]);
    XCTAssertTrue([StripeAPI canSubmitPaymentRequest:request2]);

    XCTAssertTrue([StripeAPI deviceSupportsApplePay]);
}

- (void)testSTPAPIClientBridgeKeys {
    NSString *testKey = @"pk_test_123";
    StripeAPI.defaultPublishableKey = testKey;
    XCTAssertEqualObjects(testKey, StripeAPI.defaultPublishableKey);
    StripeAPI.defaultPublishableKey = nil;
}

- (void)testSTPAPIClientBridgeSettings {
    STPAPIClient *client = [[STPAPIClient alloc] initWithPublishableKey:@"pk_test_123"];
    STPPaymentConfiguration *config = [[STPPaymentConfiguration alloc] init];
    client.configuration = config;
    XCTAssertEqual(config, client.configuration);
    
    NSString *stripeAccount = @"acct_123";
    client.stripeAccount = stripeAccount;
    XCTAssertEqualObjects(stripeAccount, client.stripeAccount);
    
    STPAppInfo *appInfo = [[STPAppInfo alloc] initWithName:@"test" partnerId:@"abc123" version:@"1.0" url:@"https://example.com"];
    client.appInfo = appInfo;
    XCTAssertEqualObjects(appInfo.name, client.appInfo.name);
    
    XCTAssertNotNil(STPAPIClient.apiVersion);
}

@end
