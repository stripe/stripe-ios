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
#import "STPTelemetryClient.h"

@interface STPAPIClient (Testing)
+ (NSDictionary *)parametersForPayment:(PKPayment *)payment;
@end

@interface STPAnalyticsClient (Testing)
+ (BOOL)shouldCollectAnalytics;
@property (nonatomic) NSSet *productUsage;
@end

@interface STPAnalyticsClientTest : XCTestCase

@end

@implementation STPAnalyticsClientTest

- (void)testShouldCollectAnalytics_alwaysFalseInTest {
    XCTAssertFalse([STPAnalyticsClient shouldCollectAnalytics]);
}

- (void)testTokenTypeFromParameters {
    STPCardParams *card = [STPFixtures cardParams];
    NSDictionary *cardDict = [self buildTokenParams:card];
    XCTAssertEqualObjects([STPAnalyticsClient tokenTypeFromParameters:cardDict], @"card");

    STPConnectAccountParams *account = [STPFixtures accountParams];
    NSDictionary *accountDict = [self buildTokenParams:account];
    XCTAssertEqualObjects([STPAnalyticsClient tokenTypeFromParameters:accountDict], @"account");

    STPBankAccountParams *bank = [STPFixtures bankAccountParams];
    NSDictionary *bankDict = [self buildTokenParams:bank];
    XCTAssertEqualObjects([STPAnalyticsClient tokenTypeFromParameters:bankDict], @"bank_account");

    PKPayment *applePay = [STPFixtures applePayPayment];
    NSDictionary *applePayDict = [self addTelemetry:[STPAPIClient parametersForPayment:applePay]];
    XCTAssertEqualObjects([STPAnalyticsClient tokenTypeFromParameters:applePayDict], @"apple_pay");
}

#pragma mark - Tests various classes report usage

- (void)testCardTextFieldAddsUsage {
    STPPaymentCardTextField *_ = [[STPPaymentCardTextField alloc] init];
    XCTAssertTrue([[STPAnalyticsClient sharedClient].productUsage containsObject:NSStringFromClass([_ class])]);
}

- (void)testPaymentContextAddsUsage{
    STPPaymentContext *_ = [[STPPaymentContext alloc] initWithCustomerContext:[STPCustomerContext new]];
    XCTAssertTrue([[STPAnalyticsClient sharedClient].productUsage containsObject:NSStringFromClass([_ class])]);
}

- (void)testApplePayContextAddsUsage{
    id delegate;
    STPApplePayContext *_ = [[STPApplePayContext alloc] initWithPaymentRequest:[STPFixtures applePayRequest] delegate:delegate];
    XCTAssertTrue([[STPAnalyticsClient sharedClient].productUsage containsObject:NSStringFromClass([_ class])]);
}

- (void)testCustomerContextAddsUsage {
    STPCustomerContext *_ = [[STPCustomerContext alloc] init];
    XCTAssertTrue([[STPAnalyticsClient sharedClient].productUsage containsObject:NSStringFromClass([_ class])]);
}


- (void)testAddCardVCAddsUsage {
    STPAddCardViewController *_ = [[STPAddCardViewController alloc] init];
    XCTAssertTrue([[STPAnalyticsClient sharedClient].productUsage containsObject:NSStringFromClass([_ class])]);
}

- (void)testBankSelectionVCAddsUsage {
    STPBankSelectionViewController *_ = [[STPBankSelectionViewController alloc] init];
    XCTAssertTrue([[STPAnalyticsClient sharedClient].productUsage containsObject:NSStringFromClass([_ class])]);
}

- (void)testShippingVCAddsUsage {
    STPPaymentConfiguration *config = [STPFixtures paymentConfiguration];
    config.requiredShippingAddressFields = [NSSet setWithObject:STPContactFieldPostalAddress];
    STPShippingAddressViewController *_ = [[STPShippingAddressViewController alloc] initWithConfiguration:config theme:[STPTheme defaultTheme] currency:nil shippingAddress:nil selectedShippingMethod:nil prefilledInformation:nil];
    XCTAssertTrue([[STPAnalyticsClient sharedClient].productUsage containsObject:NSStringFromClass([_ class])]);
}

#pragma mark - Helpers

- (NSDictionary *)buildTokenParams:(nonnull NSObject<STPFormEncodable> *)object {
    return [self addTelemetry:[STPFormEncoder dictionaryForObject:object]];
}

- (NSDictionary *)addTelemetry:(NSDictionary *)params {
    NSMutableDictionary *mutableParams = [params mutableCopy];

    // STPAPIClient adds these before determining the token type,
    // so do the same in the test
    [[STPTelemetryClient sharedInstance] addTelemetryFieldsToParams:mutableParams];

    return mutableParams;
}

@end
