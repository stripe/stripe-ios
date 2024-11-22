//
//  PaymentSheetFormFactorySnapshotTest.swift
//  StripeiOSTests
//
//  Created by Eduardo Urias on 2/23/23.
//

import StripeCoreTestUtils
@_spi(STP) @testable import StripePaymentSheet
@testable@_spi(STP) import StripePaymentsTestUtils
@_spi(STP) @testable import StripeUICore
import XCTest

final class PaymentSheetFormFactorySnapshotTest: STPSnapshotTestCase {
    override func setUp() {
        super.setUp()
        let expectation = expectation(description: "Specs loaded")
        AddressSpecProvider.shared.loadAddressSpecs {
            FormSpecProvider.shared.load { _ in
                expectation.fulfill()
            }
        }
        waitForExpectations(timeout: 1)
    }

    func testCard_AutomaticFields_NoDefaults() {
        let configuration = PaymentSheet.Configuration()
        let factory = factory(for: .card, configuration: configuration)
        let formElement = factory.make()
        let view = formElement.view
        view.autosizeHeight(width: 375)
        STPSnapshotVerifyView(view)
        XCTAssertFalse(formElement.validationState.isValid)
    }

    func testCard_AutomaticFields_DefaultAddress() {
        let defaultAddress = PaymentSheet.Address(
            city: "Vancouver",
            country: "CA",
            line1: "1200 Waterfront Center",
            line2: "Line 2",
            postalCode: "V7X 1T2",
            state: "BC"
        )
        var configuration = PaymentSheet.Configuration()
        configuration.defaultBillingDetails.address = defaultAddress
        let factory = factory(for: .card, configuration: configuration)
        let formElement = factory.make()
        let view = formElement.view
        view.autosizeHeight(width: 375)
        STPSnapshotVerifyView(view)
        XCTAssertFalse(formElement.validationState.isValid)
    }

    func testCard_AllFields_NoDefaults() {
        var configuration = PaymentSheet.Configuration()
        configuration.billingDetailsCollectionConfiguration.name = .always
        configuration.billingDetailsCollectionConfiguration.email = .always
        configuration.billingDetailsCollectionConfiguration.phone = .always
        configuration.billingDetailsCollectionConfiguration.address = .full
        let factory = factory(for: .card, configuration: configuration)
        let formElement = factory.make()
        let view = formElement.view
        view.autosizeHeight(width: 375)
        STPSnapshotVerifyView(view)
        XCTAssertFalse(formElement.validationState.isValid)
    }

    func testCard_AllFields_WithDefaults() {
        let defaultAddress = PaymentSheet.Address(
            city: "San Francisco",
            country: "US",
            line1: "510 Townsend St.",
            line2: "Line 2",
            postalCode: "94102",
            state: "CA"
        )
        var configuration = PaymentSheet.Configuration()
        configuration.defaultBillingDetails.name = "Jane Doe"
        configuration.defaultBillingDetails.email = "foo@bar.com"
        configuration.defaultBillingDetails.phone = "+15555555555"
        configuration.defaultBillingDetails.address = defaultAddress
        configuration.billingDetailsCollectionConfiguration.name = .always
        configuration.billingDetailsCollectionConfiguration.email = .always
        configuration.billingDetailsCollectionConfiguration.phone = .always
        configuration.billingDetailsCollectionConfiguration.address = .full
        let factory = factory(for: .card, configuration: configuration)
        let formElement = factory.make()
        let view = formElement.view
        view.autosizeHeight(width: 375)
        STPSnapshotVerifyView(view)
        XCTAssertFalse(formElement.validationState.isValid)
    }

    func testCard_CardInfoOnly() {
        var configuration = PaymentSheet.Configuration()
        configuration.billingDetailsCollectionConfiguration.name = .never
        configuration.billingDetailsCollectionConfiguration.email = .never
        configuration.billingDetailsCollectionConfiguration.phone = .never
        configuration.billingDetailsCollectionConfiguration.address = .never
        let factory = factory(for: .card, configuration: configuration)
        let formElement = factory.make()
        let view = formElement.view
        view.autosizeHeight(width: 375)
        STPSnapshotVerifyView(view)
        XCTAssertFalse(formElement.validationState.isValid)
    }

    func testCard_CardInfoWithName() {
        var configuration = PaymentSheet.Configuration()
        configuration.billingDetailsCollectionConfiguration.name = .always
        configuration.billingDetailsCollectionConfiguration.email = .never
        configuration.billingDetailsCollectionConfiguration.phone = .never
        configuration.billingDetailsCollectionConfiguration.address = .never
        let factory = factory(for: .card, configuration: configuration)
        let formElement = factory.make()
        let view = formElement.view
        view.autosizeHeight(width: 375)
        STPSnapshotVerifyView(view)
        XCTAssertFalse(formElement.validationState.isValid)
    }

    func testUSBankAccount_AutomaticFields_NoDefaults() {
        let configuration = PaymentSheet.Configuration()
        let factory = factory(for: .USBankAccount, configuration: configuration)
        let formElement = factory.make()
        let view = formElement.view
        view.autosizeHeight(width: 375)
        STPSnapshotVerifyView(view)
        XCTAssertFalse(formElement.validationState.isValid)
    }

    func testUSBankAccount_AutomaticFields_WithDefaults() {
        var configuration = PaymentSheet.Configuration()
        configuration.defaultBillingDetails.name = "Jane Doe"
        configuration.defaultBillingDetails.email = "foo@bar.com"
        configuration.billingDetailsCollectionConfiguration.attachDefaultsToPaymentMethod = true
        let factory = factory(for: .USBankAccount, configuration: configuration)
        let formElement = factory.make()
        let view = formElement.view
        view.autosizeHeight(width: 375)
        STPSnapshotVerifyView(view)
        XCTAssertTrue(formElement.validationState.isValid)
    }

    func testUSBankAccount_AllFields_NoDefaults() {
        var configuration = PaymentSheet.Configuration()
        configuration.billingDetailsCollectionConfiguration.name = .always
        configuration.billingDetailsCollectionConfiguration.email = .always
        configuration.billingDetailsCollectionConfiguration.phone = .always
        configuration.billingDetailsCollectionConfiguration.address = .full
        let factory = factory(for: .USBankAccount, configuration: configuration)
        let formElement = factory.make()
        let view = formElement.view
        view.autosizeHeight(width: 375)
        STPSnapshotVerifyView(view)
        XCTAssertFalse(formElement.validationState.isValid)
    }

    func testUSBankAccount_AllFields_WithDefaults() {
        let defaultAddress = PaymentSheet.Address(
            city: "San Francisco",
            country: "US",
            line1: "510 Townsend St.",
            line2: "Line 2",
            postalCode: "94102",
            state: "CA"
        )
        var configuration = PaymentSheet.Configuration()
        configuration.defaultBillingDetails.name = "Jane Doe"
        configuration.defaultBillingDetails.email = "foo@bar.com"
        configuration.defaultBillingDetails.phone = "+15555555555"
        configuration.defaultBillingDetails.address = defaultAddress
        configuration.billingDetailsCollectionConfiguration.name = .always
        configuration.billingDetailsCollectionConfiguration.email = .always
        configuration.billingDetailsCollectionConfiguration.phone = .always
        configuration.billingDetailsCollectionConfiguration.address = .full
        let factory = factory(for: .USBankAccount, configuration: configuration)
        let formElement = factory.make()
        let view = formElement.view
        view.autosizeHeight(width: 375)
        STPSnapshotVerifyView(view)
        XCTAssertTrue(formElement.validationState.isValid)
    }

    func testUSBankAccount_NoFields() {
        var configuration = PaymentSheet.Configuration()
        configuration.defaultBillingDetails.name = "Jane Doe"
        configuration.defaultBillingDetails.email = "foo@bar.com"
        configuration.billingDetailsCollectionConfiguration.attachDefaultsToPaymentMethod = true
        configuration.billingDetailsCollectionConfiguration.name = .never
        configuration.billingDetailsCollectionConfiguration.email = .never
        configuration.billingDetailsCollectionConfiguration.phone = .never
        configuration.billingDetailsCollectionConfiguration.address = .never
        let factory = factory(for: .USBankAccount, configuration: configuration)
        let formElement = factory.make()
        let view = formElement.view
        view.autosizeHeight(width: 375)
        STPSnapshotVerifyView(view)
        XCTAssertTrue(formElement.validationState.isValid)
    }

    func testUpi_AutomaticFields() {
        let configuration = PaymentSheet.Configuration()
        let factory = factory(for: .UPI, configuration: configuration)
        let formElement = factory.make()
        let view = formElement.view
        view.autosizeHeight(width: 375)
        STPSnapshotVerifyView(view)
        XCTAssertFalse(formElement.validationState.isValid)
    }

    func testUpi_AllFields_NoDefaults() {
        var configuration = PaymentSheet.Configuration()
        configuration.billingDetailsCollectionConfiguration.name = .always
        configuration.billingDetailsCollectionConfiguration.email = .always
        configuration.billingDetailsCollectionConfiguration.phone = .always
        configuration.billingDetailsCollectionConfiguration.address = .full
        let factory = factory(for: .UPI, configuration: configuration)
        let formElement = factory.make()
        let view = formElement.view
        view.autosizeHeight(width: 375)
        STPSnapshotVerifyView(view)
        XCTAssertFalse(formElement.validationState.isValid)
    }

    func testUpi_AllFields_WithDefaults() {
        let defaultAddress = PaymentSheet.Address(
            city: "San Francisco",
            country: "US",
            line1: "510 Townsend St.",
            line2: "Line 2",
            postalCode: "94102",
            state: "CA"
        )
        var configuration = PaymentSheet.Configuration()
        configuration.defaultBillingDetails.name = "Jane Doe"
        configuration.defaultBillingDetails.email = "foo@bar.com"
        configuration.defaultBillingDetails.phone = "+15555555555"
        configuration.defaultBillingDetails.address = defaultAddress
        configuration.billingDetailsCollectionConfiguration.name = .always
        configuration.billingDetailsCollectionConfiguration.email = .always
        configuration.billingDetailsCollectionConfiguration.phone = .always
        configuration.billingDetailsCollectionConfiguration.address = .full
        let factory = factory(for: .UPI, configuration: configuration)
        let formElement = factory.make()
        let view = formElement.view
        view.autosizeHeight(width: 375)
        STPSnapshotVerifyView(view)
        XCTAssertFalse(formElement.validationState.isValid)
    }

    func testUpi_SomeFields_NoDefaults() {
        // Same result as automatic fields.
        var configuration = PaymentSheet.Configuration()
        configuration.billingDetailsCollectionConfiguration.name = .always
        configuration.billingDetailsCollectionConfiguration.email = .always
        configuration.billingDetailsCollectionConfiguration.phone = .never
        configuration.billingDetailsCollectionConfiguration.address = .never
        let factory = factory(for: .UPI, configuration: configuration)
        let formElement = factory.make()
        let view = formElement.view
        view.autosizeHeight(width: 375)
        STPSnapshotVerifyView(view)
        XCTAssertFalse(formElement.validationState.isValid)
    }

    func testLpm_Afterpay_AutomaticFields_NoDefaults() {
        let configuration = PaymentSheet.Configuration()
        let factory = factory(
            for: .afterpayClearpay,
            configuration: configuration)
        let formElement = factory.make()
        let view = formElement.view
        view.autosizeHeight(width: 375)
        STPSnapshotVerifyView(view)
        XCTAssertFalse(formElement.validationState.isValid)
    }

    func testLpm_Afterpay_AllFields_NoDefaults() {

        var configuration = PaymentSheet.Configuration()
        configuration.billingDetailsCollectionConfiguration.name = .always
        configuration.billingDetailsCollectionConfiguration.email = .always
        configuration.billingDetailsCollectionConfiguration.phone = .always
        configuration.billingDetailsCollectionConfiguration.address = .full
        let factory = factory(
            for: .afterpayClearpay,
            configuration: configuration)
        let formElement = factory.make()
        let view = formElement.view
        view.autosizeHeight(width: 375)
        STPSnapshotVerifyView(view)
        XCTAssertFalse(formElement.validationState.isValid)
    }

    func testLpm_Afterpay_AllFields_WithDefaults() {
        let defaultAddress = PaymentSheet.Address(
            city: "San Francisco",
            country: "US",
            line1: "510 Townsend St.",
            line2: "Line 2",
            postalCode: "94102",
            state: "CA"
        )
        var configuration = PaymentSheet.Configuration()
        configuration.defaultBillingDetails.name = "Jane Doe"
        configuration.defaultBillingDetails.email = "foo@bar.com"
        configuration.defaultBillingDetails.phone = "+15555555555"
        configuration.defaultBillingDetails.address = defaultAddress
        configuration.billingDetailsCollectionConfiguration.name = .always
        configuration.billingDetailsCollectionConfiguration.email = .always
        configuration.billingDetailsCollectionConfiguration.phone = .always
        configuration.billingDetailsCollectionConfiguration.address = .full
        let factory = factory(
            for: .afterpayClearpay,
            configuration: configuration)
        let formElement = factory.make()
        let view = formElement.view
        view.autosizeHeight(width: 375)
        STPSnapshotVerifyView(view)
        XCTAssertTrue(formElement.validationState.isValid)
    }

    func testLpm_Afterpay_MinimalFields() {
        var configuration = PaymentSheet.Configuration()
        configuration.billingDetailsCollectionConfiguration.name = .never
        configuration.billingDetailsCollectionConfiguration.email = .never
        configuration.billingDetailsCollectionConfiguration.phone = .never
        configuration.billingDetailsCollectionConfiguration.address = .never
        let factory = factory(
            for: .afterpayClearpay,
            configuration: configuration)
        let formElement = factory.make()
        let view = formElement.view
        view.autosizeHeight(width: 375)
        STPSnapshotVerifyView(view)
        XCTAssertTrue(formElement.validationState.isValid)
    }

    func testLpm_Klarna_AutomaticFields_NoDefaults() {
        let configuration = PaymentSheet.Configuration()
        let factory = factory(
            for: .klarna,
            configuration: configuration)
        let formElement = factory.make()
        let view = formElement.view
        view.autosizeHeight(width: 375)
        STPSnapshotVerifyView(view)
        XCTAssertFalse(formElement.validationState.isValid)
    }

    func testLpm_Klarna_AllFields_NoDefaults() {
        var configuration = PaymentSheet.Configuration()
        configuration.billingDetailsCollectionConfiguration.name = .always
        configuration.billingDetailsCollectionConfiguration.email = .always
        configuration.billingDetailsCollectionConfiguration.phone = .always
        configuration.billingDetailsCollectionConfiguration.address = .full
        let factory = factory(
            for: .klarna,
            configuration: configuration)
        let formElement = factory.make()
        let view = formElement.view
        view.autosizeHeight(width: 375)
        STPSnapshotVerifyView(view)
        XCTAssertFalse(formElement.validationState.isValid)
    }

    func testLpm_Klarna_AllFields_WithDefaults() {
        let defaultAddress = PaymentSheet.Address(
            city: "San Francisco",
            country: "US",
            line1: "510 Townsend St.",
            line2: "Line 2",
            postalCode: "94102",
            state: "CA"
        )
        var configuration = PaymentSheet.Configuration()
        configuration.defaultBillingDetails.name = "Jane Doe"
        configuration.defaultBillingDetails.email = "foo@bar.com"
        configuration.defaultBillingDetails.phone = "+15555555555"
        configuration.defaultBillingDetails.address = defaultAddress
        configuration.billingDetailsCollectionConfiguration.name = .always
        configuration.billingDetailsCollectionConfiguration.email = .always
        configuration.billingDetailsCollectionConfiguration.phone = .always
        configuration.billingDetailsCollectionConfiguration.address = .full
        let factory = factory(
            for: .klarna,
            configuration: configuration)
        let formElement = factory.make()
        let view = formElement.view
        view.autosizeHeight(width: 375)
        STPSnapshotVerifyView(view)
        XCTAssertTrue(formElement.validationState.isValid)
    }

    func testLpm_Klarna_MinimalFields() {
        var configuration = PaymentSheet.Configuration()
        configuration.billingDetailsCollectionConfiguration.name = .never
        configuration.billingDetailsCollectionConfiguration.email = .never
        configuration.billingDetailsCollectionConfiguration.phone = .never
        configuration.billingDetailsCollectionConfiguration.address = .never
        let factory = factory(
            for: .klarna,
            configuration: configuration)
        let formElement = factory.make()
        let view = formElement.view
        view.autosizeHeight(width: 375)
        STPSnapshotVerifyView(view)
        XCTAssertTrue(formElement.validationState.isValid)
    }

}

extension PaymentSheetFormFactorySnapshotTest {
    private func factory(
        for paymentMethodType: STPPaymentMethodType,
        configuration: PaymentSheet.Configuration
    ) -> PaymentSheetFormFactory {
        let intent = Intent._testPaymentIntent(paymentMethodTypes: [paymentMethodType])
        return PaymentSheetFormFactory(
            intent: intent,
            elementsSession: ._testValue(intent: intent),
            configuration: .paymentSheet(configuration),
            paymentMethod: .stripe(paymentMethodType)
        )
    }
}
