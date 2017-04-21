//
//  STPAnalyticsClientTest.m
//  Stripe
//
//  Created by Ben Guo on 4/22/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "STPAnalyticsClient.h"
#import "STPFixtures.h"
#import "STPFormEncoder.h"

@interface STPAPIClient (Testing)
+ (NSDictionary *)parametersForPayment:(PKPayment *)payment;
@end

@interface STPAnalyticsClient (Testing)
+ (BOOL)shouldCollectAnalytics;
@end

@interface STPAnalyticsClientTest : XCTestCase

@end

@implementation STPAnalyticsClientTest

- (void)testShouldCollectAnalytics_alwaysFalseInTest {
    XCTAssertFalse([STPAnalyticsClient shouldCollectAnalytics]);
}

- (void)testTokenTypeFromParameters {
    STPCardParams *card = [STPFixtures cardParams];
    NSDictionary *cardDict = [STPFormEncoder dictionaryForObject:card];
    XCTAssertEqualObjects([STPAnalyticsClient tokenTypeFromParameters:cardDict], @"card");

    STPBankAccountParams *bank = [STPFixtures bankAccountParams];
    NSDictionary *bankDict = [STPFormEncoder dictionaryForObject:bank];
    XCTAssertEqualObjects([STPAnalyticsClient tokenTypeFromParameters:bankDict], @"bank_account");

    PKPayment *applePay = [STPFixtures applePayPayment];
    NSDictionary *applePayDict = [STPAPIClient parametersForPayment:applePay];
    XCTAssertEqualObjects([STPAnalyticsClient tokenTypeFromParameters:applePayDict], @"apple_pay");
}

@end
