//  Converted to Swift 5.8.1 by Swiftify v5.8.28463 - https://swiftify.com/
import Foundation
import XCTest

@testable@_spi(STP) import Stripe
@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePayments
@testable@_spi(STP) import StripePaymentSheet
@testable@_spi(STP) import StripePaymentsUI
//
//  STPPaymentConfigurationTest.swift
//  Stripe
//
//  Created by Joey Dong on 7/18/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

import OCMock
import StripeCore

class STPPaymentConfigurationTest: XCTestCase {
    func testSharedConfiguration() {
        XCTAssertEqual(STPPaymentConfiguration.shared(), STPPaymentConfiguration.shared())
    }

    func testInit() {
        let paymentConfiguration = STPPaymentConfiguration()

        XCTAssertFalse(paymentConfiguration.fpxEnabled)
        XCTAssertEqual(paymentConfiguration.requiredBillingAddressFields.rawValue, Int(STPBillingAddressFieldsPostalCode))
        XCTAssertNil(paymentConfiguration.requiredShippingAddressFields.rawValue)
        XCTAssert(paymentConfiguration.verifyPrefilledShippingAddress)
        XCTAssertEqual(paymentConfiguration.shippingType, STPShippingType.shipping.rawValue)
        XCTAssertEqual(paymentConfiguration.companyName, "xctest")
        XCTAssertNil(paymentConfiguration.appleMerchantIdentifier)
        XCTAssert(paymentConfiguration.canDeletePaymentOptions)
        XCTAssertFalse(paymentConfiguration.cardScanningEnabled)
    }

    func testApplePayEnabledSatisfied() {
        let stripeMock = OCMClassMock(StripeAPI.self)
        OCMStub(stripeMock?.deviceSupportsApplePay()).andReturn(true)

        let paymentConfiguration = STPPaymentConfiguration()
        paymentConfiguration.appleMerchantIdentifier = "appleMerchantIdentifier"

        XCTAssert(paymentConfiguration.applePayEnabled())
    }

    func testApplePayEnabledMissingAppleMerchantIdentifier() {
        let stripeMock = OCMClassMock(StripeAPI.self)
        OCMStub(stripeMock?.deviceSupportsApplePay()).andReturn(true)

        let paymentConfiguration = STPPaymentConfiguration()
        paymentConfiguration.appleMerchantIdentifier = nil

        XCTAssertFalse(paymentConfiguration.applePayEnabled())
    }

    func testApplePayEnabledDisallowAdditionalPaymentOptions() {
        let stripeMock = OCMClassMock(StripeAPI.self)
        OCMStub(stripeMock?.deviceSupportsApplePay()).andReturn(true)

        let paymentConfiguration = STPPaymentConfiguration()
        paymentConfiguration.appleMerchantIdentifier = "appleMerchantIdentifier"
        paymentConfiguration.applePayEnabled = false

        XCTAssertFalse(paymentConfiguration.applePayEnabled())
    }

    func testApplePayEnabledMisisngDeviceSupport() {
        let paymentAuthControllerMock = OCMClassMock(PKPaymentAuthorizationController.self)
        OCMStub(paymentAuthControllerMock?.canMakePayments(usingNetworks: OCMArg.any())).andReturn(false)

        let paymentConfiguration = STPPaymentConfiguration()
        paymentConfiguration.appleMerchantIdentifier = "appleMerchantIdentifier"

        XCTAssertFalse(paymentConfiguration.applePayEnabled())
        paymentAuthControllerMock?.stopMocking()
    }

    // MARK: - Description

    func testDescription() {
        let paymentConfiguration = STPPaymentConfiguration()
        XCTAssert(paymentConfiguration.description)
    }

    // MARK: - NSCopying

    func testCopyWithZone() {
        let allFields = Set<AnyHashable>([
            STPContactField.postalAddress,
            STPContactField.emailAddress,
            STPContactField.phoneNumber,
            STPContactField.name
        ]) as? Set<STPContactField>

        let paymentConfigurationA = STPPaymentConfiguration()
        //#pragma clang diagnostic push
        //#pragma clang diagnostic ignored "-Wdeprecated"
        paymentConfigurationA.publishableKey = "publishableKey"
        paymentConfigurationA.stripeAccount = "stripeAccount"
        //#pragma clang diagnostic pop
        paymentConfigurationA.applePayEnabled = true
        paymentConfigurationA.requiredBillingAddressFields = STPBillingAddressFieldsFull
        if let allFields {
            paymentConfigurationA.requiredShippingAddressFields = allFields
        }
        paymentConfigurationA.verifyPrefilledShippingAddress = false
        paymentConfigurationA.availableCountries = Set<AnyHashable>(["US", "CA", "BT"])
        paymentConfigurationA.shippingType = STPShippingType.delivery
        paymentConfigurationA.companyName = "companyName"
        paymentConfigurationA.appleMerchantIdentifier = "appleMerchantIdentifier"
        paymentConfigurationA.canDeletePaymentOptions = false
        paymentConfigurationA.cardScanningEnabled = false

        let paymentConfigurationB = paymentConfigurationA.copy()
        XCTAssertNotEqual(paymentConfigurationA, paymentConfigurationB)

        //#pragma clang diagnostic push
        //#pragma clang diagnostic ignored "-Wdeprecated"
        XCTAssertEqual(paymentConfigurationB?.publishableKey, "publishableKey")
        XCTAssertEqual(paymentConfigurationB?.stripeAccount, "stripeAccount")
        //#pragma clang diagnostic pop
        XCTAssertTrue(paymentConfigurationB?.applePayEnabled)
        XCTAssertEqual(paymentConfigurationB?.requiredBillingAddressFields.rawValue ?? 0, Int(STPBillingAddressFieldsFull))
        XCTAssertEqual(paymentConfigurationB?.requiredShippingAddressFields, allFields)
        XCTAssertFalse(paymentConfigurationB?.verifyPrefilledShippingAddress)
        XCTAssertEqual(paymentConfigurationB?.shippingType ?? 0, STPShippingType.delivery.rawValue)
        XCTAssertEqual(paymentConfigurationB?.companyName, "companyName")
        XCTAssertEqual(paymentConfigurationB?.appleMerchantIdentifier, "appleMerchantIdentifier")
        let availableCountries = Set<AnyHashable>(["US", "CA", "BT"])
        XCTAssertEqual(paymentConfigurationB?.availableCountries, availableCountries)
        XCTAssertEqual(paymentConfigurationA.canDeletePaymentOptions, paymentConfigurationB?.canDeletePaymentOptions ?? 0)
        XCTAssertEqual(paymentConfigurationA.cardScanningEnabled, paymentConfigurationB?.cardScanningEnabled ?? 0)
    }
}
