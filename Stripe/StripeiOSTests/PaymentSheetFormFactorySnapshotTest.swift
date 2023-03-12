//
//  PaymentSheetFormFactorySnapshotTest.swift
//  StripeiOSTests
//
//  Created by Eduardo Urias on 2/23/23.
//

import iOSSnapshotTestCase
import StripeCoreTestUtils
@_spi(STP) @testable import StripePaymentSheet
@_spi(STP) @testable import StripeUICore
import XCTest

final class PaymentSheetFormFactorySnapshotTest: FBSnapshotTestCase {
    override func setUp() {
        super.setUp()
//        recordMode = true
    }

    func testCard_AutomaticFields_NoDefaults() {
        let configuration = PaymentSheet.Configuration()
        let factory = factory(for: .card, configuration: configuration)
        let formElement = factory.make()
        let view = formElement.view
        view.autosizeHeight(width: 375)
        STPSnapshotVerifyView(view)
    }

    func testCard_AutomaticFields_DefaultAddress() {
        let defaultAddress = PaymentSheet.Address(
            city: "San Francisco",
            country: "US",
            line1: "510 Townsend St.",
            line2: "Line 2",
            postalCode: "94102",
            state: "CA"
        )
        var configuration = PaymentSheet.Configuration()
        configuration.defaultBillingDetails.address = defaultAddress
        let factory = factory(for: .card, configuration: configuration)
        let formElement = factory.make()
        let view = formElement.view
        view.autosizeHeight(width: 375)
        STPSnapshotVerifyView(view)
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
    }

    func testUSBankAccount_AutomaticFields_NoDefaults() {
        let configuration = PaymentSheet.Configuration()
        let factory = factory(for: .USBankAccount, configuration: configuration)
        let formElement = factory.make()
        let view = formElement.view
        view.autosizeHeight(width: 375)
        STPSnapshotVerifyView(view)
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
    }

    func testUpi_AutomaticFields() {
        let configuration = PaymentSheet.Configuration()
        let factory = factory(for: .UPI, configuration: configuration)
        let formElement = factory.make()
        let view = formElement.view
        view.autosizeHeight(width: 375)
        STPSnapshotVerifyView(view)
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
    }
}

extension PaymentSheetFormFactorySnapshotTest {
    private func usAddressSpecProvider() -> AddressSpecProvider {
        let specProvider = AddressSpecProvider()
        specProvider.addressSpecs = [
            "US": AddressSpec(
                format: "NOACSZ",
                require: "ACSZ",
                cityNameType: .city,
                stateNameType: .state,
                zip: "",
                zipNameType: .zip
            ),
        ]
        return specProvider
    }

    private func factory(
        for paymentMethodType: PaymentSheet.PaymentMethodType,
        configuration: PaymentSheet.Configuration
    ) -> PaymentSheetFormFactory {
        let paymentIntent = STPFixtures.makePaymentIntent(paymentMethodTypes: [paymentMethodType.stpPaymentMethodType!])
        return PaymentSheetFormFactory(
            intent: .paymentIntent(paymentIntent),
            configuration: configuration,
            paymentMethod: paymentMethodType,
            addressSpecProvider: usAddressSpecProvider()
        )
    }
}
