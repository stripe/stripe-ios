//
//  STPPaymentConfigurationTest.m
//  Stripe
//
//  Created by Joey Dong on 7/18/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>

#import "STPPaymentConfiguration.h"
#import "STPPaymentConfiguration+Private.h"

#import "NSBundle+Stripe_AppName.h"
#import "Stripe.h"

@interface STPPaymentContext (Testing)
@property (nonatomic) STPAPIClient *apiClient;
@end

@interface STPPaymentConfigurationTest : XCTestCase

@end

@implementation STPPaymentConfigurationTest

- (void)testSharedConfiguration {
    XCTAssertEqual([STPPaymentConfiguration sharedConfiguration], [STPPaymentConfiguration sharedConfiguration]);
}

- (void)testInit {
    id bundleMock = OCMClassMock([NSBundle class]);
    OCMStub([bundleMock stp_applicationName]).andReturn(@"applicationName");

    STPPaymentConfiguration *paymentConfiguration = [[STPPaymentConfiguration alloc] init];

    XCTAssertNil(paymentConfiguration.publishableKey);
    XCTAssertEqual(paymentConfiguration.additionalPaymentOptions, STPPaymentOptionTypeDefault);
    XCTAssertEqual(paymentConfiguration.requiredBillingAddressFields, STPBillingAddressFieldsNone);
    XCTAssertNil(paymentConfiguration.requiredShippingAddressFields);
    XCTAssert(paymentConfiguration.verifyPrefilledShippingAddress);
    XCTAssertEqual(paymentConfiguration.shippingType, STPShippingTypeShipping);
    XCTAssertEqualObjects(paymentConfiguration.companyName, @"applicationName");
    XCTAssertNil(paymentConfiguration.appleMerchantIdentifier);
    XCTAssertNil(paymentConfiguration.stripeAccount);
    XCTAssert(paymentConfiguration.canDeletePaymentOptions);
}

- (void)testApplePayEnabledSatisfied {
    id stripeMock = OCMClassMock([Stripe class]);
    OCMStub([stripeMock deviceSupportsApplePay]).andReturn(YES);

    STPPaymentConfiguration *paymentConfiguration = [[STPPaymentConfiguration alloc] init];
    paymentConfiguration.appleMerchantIdentifier = @"appleMerchantIdentifier";
    paymentConfiguration.additionalPaymentOptions = STPPaymentOptionTypeDefault;

    XCTAssert([paymentConfiguration applePayEnabled]);
}

- (void)testApplePayEnabledMissingAppleMerchantIdentifier {
    id stripeMock = OCMClassMock([Stripe class]);
    OCMStub([stripeMock deviceSupportsApplePay]).andReturn(YES);

    STPPaymentConfiguration *paymentConfiguration = [[STPPaymentConfiguration alloc] init];
    paymentConfiguration.appleMerchantIdentifier = nil;
    paymentConfiguration.additionalPaymentOptions = STPPaymentOptionTypeDefault;

    XCTAssertFalse([paymentConfiguration applePayEnabled]);
}

- (void)testApplePayEnabledDisallowAdditionalPaymentOptions {
    id stripeMock = OCMClassMock([Stripe class]);
    OCMStub([stripeMock deviceSupportsApplePay]).andReturn(YES);

    STPPaymentConfiguration *paymentConfiguration = [[STPPaymentConfiguration alloc] init];
    paymentConfiguration.appleMerchantIdentifier = @"appleMerchantIdentifier";
    paymentConfiguration.additionalPaymentOptions = STPPaymentOptionTypeNone;

    XCTAssertFalse([paymentConfiguration applePayEnabled]);
}

- (void)testApplePayEnabledMisisngDeviceSupport {
    id stripeMock = OCMClassMock([Stripe class]);
    OCMStub([stripeMock deviceSupportsApplePay]).andReturn(NO);

    STPPaymentConfiguration *paymentConfiguration = [[STPPaymentConfiguration alloc] init];
    paymentConfiguration.appleMerchantIdentifier = @"appleMerchantIdentifier";
    paymentConfiguration.additionalPaymentOptions = STPPaymentOptionTypeDefault;

    XCTAssertFalse([paymentConfiguration applePayEnabled]);
}

- (void)testStripeAccount {
    // Setting stripeAccount...
    STPPaymentConfiguration *configuration = [STPPaymentConfiguration sharedConfiguration];
    configuration.stripeAccount = @"testStripeAccount";
    
    // ...should set STPPaymentContext's apiClient...
    STPPaymentContext *paymentContext = [[STPPaymentContext alloc] initWithCustomerContext:[STPCustomerContext new]];
    XCTAssertEqualObjects(configuration.stripeAccount, paymentContext.apiClient.stripeAccount);
    
    // ...and APIClient.sharedClient
    XCTAssertEqualObjects(configuration.stripeAccount, [STPAPIClient sharedClient].stripeAccount);
}

#pragma mark - Description

- (void)testDescription {
    STPPaymentConfiguration *paymentConfiguration = [[STPPaymentConfiguration alloc] init];
    XCTAssert(paymentConfiguration.description);
}

#pragma mark - NSCopying

- (void)testCopyWithZone {
    NSSet<STPContactField> *allFields = [NSSet setWithArray:@[STPContactFieldPostalAddress,
                                                              STPContactFieldEmailAddress,
                                                              STPContactFieldPhoneNumber,
                                                              STPContactFieldName]];

    STPPaymentConfiguration *paymentConfigurationA = [[STPPaymentConfiguration alloc] init];
    paymentConfigurationA.publishableKey = @"publishableKey";
    paymentConfigurationA.additionalPaymentOptions = STPPaymentOptionTypeApplePay;
    paymentConfigurationA.requiredBillingAddressFields = STPBillingAddressFieldsFull;
    paymentConfigurationA.requiredShippingAddressFields = allFields;
    paymentConfigurationA.verifyPrefilledShippingAddress = NO;
    paymentConfigurationA.availableCountries = [NSSet setWithArray:@[@"US", @"CA", @"BT"]];
    paymentConfigurationA.shippingType = STPShippingTypeDelivery;
    paymentConfigurationA.companyName = @"companyName";
    paymentConfigurationA.appleMerchantIdentifier = @"appleMerchantIdentifier";
    paymentConfigurationA.canDeletePaymentOptions = NO;
    paymentConfigurationA.stripeAccount = @"acct_123";

    STPPaymentConfiguration *paymentConfigurationB = [paymentConfigurationA copy];
    XCTAssertNotEqual(paymentConfigurationA, paymentConfigurationB);

    XCTAssertEqualObjects(paymentConfigurationB.publishableKey, @"publishableKey");
    XCTAssertEqual(paymentConfigurationB.additionalPaymentOptions, STPPaymentOptionTypeApplePay);
    XCTAssertEqual(paymentConfigurationB.requiredBillingAddressFields, STPBillingAddressFieldsFull);
    XCTAssertEqualObjects(paymentConfigurationB.requiredShippingAddressFields, allFields);
    XCTAssertFalse(paymentConfigurationB.verifyPrefilledShippingAddress);
    XCTAssertEqual(paymentConfigurationB.shippingType, STPShippingTypeDelivery);
    XCTAssertEqualObjects(paymentConfigurationB.companyName, @"companyName");
    XCTAssertEqualObjects(paymentConfigurationB.appleMerchantIdentifier, @"appleMerchantIdentifier");
    NSSet *availableCountries = [NSSet setWithArray:@[@"US", @"CA", @"BT"]];
    XCTAssertEqualObjects(paymentConfigurationB.availableCountries, availableCountries);
    XCTAssertEqual(paymentConfigurationA.canDeletePaymentOptions, paymentConfigurationB.canDeletePaymentOptions);
    XCTAssertEqualObjects(paymentConfigurationA.stripeAccount, @"acct_123");
}

@end
