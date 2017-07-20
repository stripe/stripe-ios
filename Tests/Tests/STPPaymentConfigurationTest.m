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
    XCTAssertEqual(paymentConfiguration.additionalPaymentMethods, STPPaymentMethodTypeAll);
    XCTAssertEqual(paymentConfiguration.requiredBillingAddressFields, STPBillingAddressFieldsNone);
    XCTAssertEqual(paymentConfiguration.requiredShippingAddressFields, PKAddressFieldNone);
    XCTAssert(paymentConfiguration.verifyPrefilledShippingAddress);
    XCTAssertEqual(paymentConfiguration.shippingType, STPShippingTypeShipping);
    XCTAssertEqualObjects(paymentConfiguration.companyName, @"applicationName");
    XCTAssertNil(paymentConfiguration.appleMerchantIdentifier);
    XCTAssert(paymentConfiguration.canDeletePaymentMethods);
}

- (void)testApplePayEnabledSatisfied {
    id stripeMock = OCMClassMock([Stripe class]);
    OCMStub([stripeMock deviceSupportsApplePay]).andReturn(YES);

    STPPaymentConfiguration *paymentConfiguration = [[STPPaymentConfiguration alloc] init];
    paymentConfiguration.appleMerchantIdentifier = @"appleMerchantIdentifier";
    paymentConfiguration.additionalPaymentMethods = STPPaymentMethodTypeAll;

    XCTAssert([paymentConfiguration applePayEnabled]);
}

- (void)testApplePayEnabledMissingAppleMerchantIdentifier {
    id stripeMock = OCMClassMock([Stripe class]);
    OCMStub([stripeMock deviceSupportsApplePay]).andReturn(YES);

    STPPaymentConfiguration *paymentConfiguration = [[STPPaymentConfiguration alloc] init];
    paymentConfiguration.appleMerchantIdentifier = nil;
    paymentConfiguration.additionalPaymentMethods = STPPaymentMethodTypeAll;

    XCTAssertFalse([paymentConfiguration applePayEnabled]);
}

- (void)testApplePayEnabledDisallowAdditionalPaymentMethods {
    id stripeMock = OCMClassMock([Stripe class]);
    OCMStub([stripeMock deviceSupportsApplePay]).andReturn(YES);

    STPPaymentConfiguration *paymentConfiguration = [[STPPaymentConfiguration alloc] init];
    paymentConfiguration.appleMerchantIdentifier = @"appleMerchantIdentifier";
    paymentConfiguration.additionalPaymentMethods = STPPaymentMethodTypeNone;

    XCTAssertFalse([paymentConfiguration applePayEnabled]);
}

- (void)testApplePayEnabledMisisngDeviceSupport {
    id stripeMock = OCMClassMock([Stripe class]);
    OCMStub([stripeMock deviceSupportsApplePay]).andReturn(NO);

    STPPaymentConfiguration *paymentConfiguration = [[STPPaymentConfiguration alloc] init];
    paymentConfiguration.appleMerchantIdentifier = @"appleMerchantIdentifier";
    paymentConfiguration.additionalPaymentMethods = STPPaymentMethodTypeAll;

    XCTAssertFalse([paymentConfiguration applePayEnabled]);
}

#pragma mark - Description

- (void)testDescription {
    STPPaymentConfiguration *paymentConfiguration = [[STPPaymentConfiguration alloc] init];
    XCTAssert(paymentConfiguration.description);
}

#pragma mark - NSCopying

- (void)testCopyWithZone {
    STPPaymentConfiguration *paymentConfigurationA = [[STPPaymentConfiguration alloc] init];
    paymentConfigurationA.publishableKey = @"publishableKey";
    paymentConfigurationA.additionalPaymentMethods = STPPaymentMethodTypeApplePay;
    paymentConfigurationA.requiredBillingAddressFields = STPBillingAddressFieldsFull;
    paymentConfigurationA.requiredShippingAddressFields = PKAddressFieldAll;
    paymentConfigurationA.verifyPrefilledShippingAddress = NO;
    paymentConfigurationA.shippingType = STPShippingTypeDelivery;
    paymentConfigurationA.companyName = @"companyName";
    paymentConfigurationA.appleMerchantIdentifier = @"appleMerchantIdentifier";
    paymentConfigurationA.canDeletePaymentMethods = NO;

    STPPaymentConfiguration *paymentConfigurationB = [paymentConfigurationA copy];
    XCTAssertNotEqual(paymentConfigurationA, paymentConfigurationB);

    XCTAssertEqualObjects(paymentConfigurationB.publishableKey, @"publishableKey");
    XCTAssertEqual(paymentConfigurationB.additionalPaymentMethods, STPPaymentMethodTypeApplePay);
    XCTAssertEqual(paymentConfigurationB.requiredBillingAddressFields, STPBillingAddressFieldsFull);
    XCTAssertEqual(paymentConfigurationB.requiredShippingAddressFields, PKAddressFieldAll);
    XCTAssertFalse(paymentConfigurationB.verifyPrefilledShippingAddress);
    XCTAssertEqual(paymentConfigurationB.shippingType, STPShippingTypeDelivery);
    XCTAssertEqualObjects(paymentConfigurationB.companyName, @"companyName");
    XCTAssertEqualObjects(paymentConfigurationB.appleMerchantIdentifier, @"appleMerchantIdentifier");
    XCTAssertEqual(paymentConfigurationA.canDeletePaymentMethods, paymentConfigurationB.canDeletePaymentMethods);
}

@end
