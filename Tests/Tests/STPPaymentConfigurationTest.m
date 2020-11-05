//
//  STPPaymentConfigurationTest.m
//  Stripe
//
//  Created by Joey Dong on 7/18/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>







@interface STPPaymentConfigurationTest : XCTestCase

@end

@implementation STPPaymentConfigurationTest

- (void)testSharedConfiguration {
    XCTAssertEqual([STPPaymentConfiguration sharedConfiguration], [STPPaymentConfiguration sharedConfiguration]);
}

- (void)testInit {
    STPPaymentConfiguration *paymentConfiguration = [[STPPaymentConfiguration alloc] init];
    
    XCTAssertFalse(paymentConfiguration.fpxEnabled);
    XCTAssertEqual(paymentConfiguration.requiredBillingAddressFields, STPBillingAddressFieldsPostalCode);
    XCTAssertNil(paymentConfiguration.requiredShippingAddressFields);
    XCTAssert(paymentConfiguration.verifyPrefilledShippingAddress);
    XCTAssertEqual(paymentConfiguration.shippingType, STPShippingTypeShipping);
    XCTAssertEqualObjects(paymentConfiguration.companyName, @"xctest");
    XCTAssertNil(paymentConfiguration.appleMerchantIdentifier);
    XCTAssert(paymentConfiguration.canDeletePaymentOptions);
    XCTAssert(paymentConfiguration.cardScanningEnabled);
}

- (void)testApplePayEnabledSatisfied {
    id stripeMock = OCMClassMock([StripeAPI class]);
    OCMStub([stripeMock deviceSupportsApplePay]).andReturn(YES);

    STPPaymentConfiguration *paymentConfiguration = [[STPPaymentConfiguration alloc] init];
    paymentConfiguration.appleMerchantIdentifier = @"appleMerchantIdentifier";

    XCTAssert([paymentConfiguration applePayEnabled]);
}

- (void)testApplePayEnabledMissingAppleMerchantIdentifier {
    id stripeMock = OCMClassMock([StripeAPI class]);
    OCMStub([stripeMock deviceSupportsApplePay]).andReturn(YES);

    STPPaymentConfiguration *paymentConfiguration = [[STPPaymentConfiguration alloc] init];
    paymentConfiguration.appleMerchantIdentifier = nil;

    XCTAssertFalse([paymentConfiguration applePayEnabled]);
}

- (void)testApplePayEnabledDisallowAdditionalPaymentOptions {
    id stripeMock = OCMClassMock([StripeAPI class]);
    OCMStub([stripeMock deviceSupportsApplePay]).andReturn(YES);

    STPPaymentConfiguration *paymentConfiguration = [[STPPaymentConfiguration alloc] init];
    paymentConfiguration.appleMerchantIdentifier = @"appleMerchantIdentifier";
    paymentConfiguration.applePayEnabled = false;

    XCTAssertFalse([paymentConfiguration applePayEnabled]);
}

- (void)testApplePayEnabledMisisngDeviceSupport {
    id stripeMock = OCMClassMock([StripeAPI class]);
    OCMStub([stripeMock deviceSupportsApplePay]).andReturn(NO);

    STPPaymentConfiguration *paymentConfiguration = [[STPPaymentConfiguration alloc] init];
    paymentConfiguration.appleMerchantIdentifier = @"appleMerchantIdentifier";

    XCTAssertFalse([paymentConfiguration applePayEnabled]);
}

#pragma mark - Description

- (void)testDescription {
    STPPaymentConfiguration *paymentConfiguration = [[STPPaymentConfiguration alloc] init];
    XCTAssert(paymentConfiguration.description);
}

#pragma mark - NSCopying

- (void)testCopyWithZone {
    NSSet<STPContactField *> *allFields = [NSSet setWithArray:@[STPContactField.postalAddress,
                                                              STPContactField.emailAddress,
                                                              STPContactField.phoneNumber,
                                                              STPContactField.name]];

    STPPaymentConfiguration *paymentConfigurationA = [[STPPaymentConfiguration alloc] init];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"
    paymentConfigurationA.publishableKey = @"publishableKey";
    paymentConfigurationA.stripeAccount = @"stripeAccount";
#pragma clang diagnostic pop
    paymentConfigurationA.applePayEnabled = YES;
    paymentConfigurationA.requiredBillingAddressFields = STPBillingAddressFieldsFull;
    paymentConfigurationA.requiredShippingAddressFields = allFields;
    paymentConfigurationA.verifyPrefilledShippingAddress = NO;
    paymentConfigurationA.availableCountries = [NSSet setWithArray:@[@"US", @"CA", @"BT"]];
    paymentConfigurationA.shippingType = STPShippingTypeDelivery;
    paymentConfigurationA.companyName = @"companyName";
    paymentConfigurationA.appleMerchantIdentifier = @"appleMerchantIdentifier";
    paymentConfigurationA.canDeletePaymentOptions = NO;
    paymentConfigurationA.cardScanningEnabled = YES;

    STPPaymentConfiguration *paymentConfigurationB = [paymentConfigurationA copy];
    XCTAssertNotEqual(paymentConfigurationA, paymentConfigurationB);
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"
    XCTAssertEqualObjects(paymentConfigurationB.publishableKey, @"publishableKey");
    XCTAssertEqualObjects(paymentConfigurationB.stripeAccount, @"stripeAccount");
#pragma clang diagnostic pop
    XCTAssertTrue(paymentConfigurationB.applePayEnabled);
    XCTAssertEqual(paymentConfigurationB.requiredBillingAddressFields, STPBillingAddressFieldsFull);
    XCTAssertEqualObjects(paymentConfigurationB.requiredShippingAddressFields, allFields);
    XCTAssertFalse(paymentConfigurationB.verifyPrefilledShippingAddress);
    XCTAssertEqual(paymentConfigurationB.shippingType, STPShippingTypeDelivery);
    XCTAssertEqualObjects(paymentConfigurationB.companyName, @"companyName");
    XCTAssertEqualObjects(paymentConfigurationB.appleMerchantIdentifier, @"appleMerchantIdentifier");
    NSSet *availableCountries = [NSSet setWithArray:@[@"US", @"CA", @"BT"]];
    XCTAssertEqualObjects(paymentConfigurationB.availableCountries, availableCountries);
    XCTAssertEqual(paymentConfigurationA.canDeletePaymentOptions, paymentConfigurationB.canDeletePaymentOptions);
    XCTAssertEqual(paymentConfigurationA.cardScanningEnabled, paymentConfigurationB.cardScanningEnabled);
}

@end
