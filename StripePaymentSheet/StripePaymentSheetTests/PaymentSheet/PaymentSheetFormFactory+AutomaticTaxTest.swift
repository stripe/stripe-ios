//
//  PaymentSheetFormFactory+AutomaticTaxTest.swift
//  StripePaymentSheetTests
//
//  Created by Nick Porter on 7/13/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

import XCTest

@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePayments
@testable@_spi(STP) import StripePaymentSheet
@testable@_spi(STP) import StripePaymentsTestUtils
@testable@_spi(STP) import StripeUICore

@MainActor
final class PaymentSheetFormFactoryAutomaticTaxTest: XCTestCase {

    private func makeSpecProvider() -> AddressSpecProvider {
        let provider = AddressSpecProvider()
        provider.addressSpecs = [
            "US": AddressSpec(format: "ACSZ", require: "ACSZ", cityNameType: .city, stateNameType: .state, zip: "", zipNameType: .zip, subKeys: ["CA", "NY"], subLabels: ["California", "New York"]),
            "CA": AddressSpec(format: "ACSZ", require: "ACSZ", cityNameType: .city, stateNameType: .province, zip: "", zipNameType: .postal_code, subKeys: ["AB", "ON"], subLabels: ["Alberta", "Ontario"]),
            "FR": AddressSpec(format: "ACZ", require: "ACZ", cityNameType: .city, stateNameType: .province, zip: "", zipNameType: .postal_code),
        ]
        return provider
    }

    private func makeCheckoutIntent(automaticTaxEnabled: Bool = true, addressSource: String = "session.billing") -> Intent {
        let overrides: [String: Any] = [
            "status": "open",
            "currency": "usd",
            "tax_context": [
                "automatic_tax_enabled": automaticTaxEnabled,
                "automatic_tax_address_source": addressSource,
            ],
        ]
        return .checkout(Checkout(apiResponse: CheckoutTestHelpers.makeSession(overrides)))
    }

    private func makeConfiguration(
        country: String?,
        address: PaymentSheet.BillingDetailsCollectionConfiguration.AddressCollectionMode = .automatic
    ) -> PaymentSheet.Configuration {
        var config = PaymentSheet.Configuration()
        config.billingDetailsCollectionConfiguration.address = address
        if let country {
            config.defaultBillingDetails.address.country = country
        }
        return config
    }

    private func makeForm(
        paymentMethod: STPPaymentMethodType,
        intent: Intent,
        config: PaymentSheet.Configuration,
        specProvider: AddressSpecProvider
    ) -> PaymentMethodElement {
        let factory = PaymentSheetFormFactory(
            intent: intent,
            elementsSession: ._testCardValue(),
            configuration: .paymentElement(config),
            paymentMethod: .stripe(paymentMethod),
            addressSpecProvider: specProvider
        )
        return factory.make()
    }

    private func addressSection(in form: PaymentMethodElement) -> AddressSectionElement? {
        form.getAllUnwrappedSubElements().compactMap { $0 as? AddressSectionElement }.first
    }

    func testUSRequiresFullAddress() throws {
        let form = makeForm(paymentMethod: .card, intent: makeCheckoutIntent(), config: makeConfiguration(country: "US"), specProvider: makeSpecProvider())
        let section = try XCTUnwrap(addressSection(in: form))
        XCTAssertEqual(section.collectionMode, .autoCompletable)
    }

    func testCACollectsProvince() throws {
        let form = makeForm(paymentMethod: .card, intent: makeCheckoutIntent(), config: makeConfiguration(country: "CA"), specProvider: makeSpecProvider())
        let section = try XCTUnwrap(addressSection(in: form))
        XCTAssertEqual(section.collectionMode, .countryPostalAndState)
        XCTAssertNotNil(section.state)
        XCTAssertNotNil(section.postalCode)
        XCTAssertNil(section.line1)
        XCTAssertNil(section.city)
    }

    func testOtherCountryUnchanged() throws {
        let form = makeForm(paymentMethod: .card, intent: makeCheckoutIntent(), config: makeConfiguration(country: "FR"), specProvider: makeSpecProvider())
        let section = try XCTUnwrap(addressSection(in: form))
        XCTAssertEqual(section.collectionMode, .countryAndPostal())
        XCTAssertNil(section.state)
    }

    func testAutomaticTaxDisabled() throws {
        let intent = makeCheckoutIntent(automaticTaxEnabled: false)
        let form = makeForm(paymentMethod: .card, intent: intent, config: makeConfiguration(country: "US"), specProvider: makeSpecProvider())
        let section = try XCTUnwrap(addressSection(in: form))
        XCTAssertEqual(section.collectionMode, .countryAndPostal())
    }

    func testTaxSourcedFromShippingAddressUnaffected() throws {
        let intent = makeCheckoutIntent(addressSource: "session.shipping")
        let form = makeForm(paymentMethod: .card, intent: intent, config: makeConfiguration(country: "US"), specProvider: makeSpecProvider())
        let section = try XCTUnwrap(addressSection(in: form))
        XCTAssertEqual(section.collectionMode, .countryAndPostal())
    }

    func testReEvaluatesOnCountryChange() throws {
        let form = makeForm(paymentMethod: .card, intent: makeCheckoutIntent(), config: makeConfiguration(country: "FR"), specProvider: makeSpecProvider())
        let section = try XCTUnwrap(addressSection(in: form))
        XCTAssertEqual(section.collectionMode, .countryAndPostal())

        let usIndex = try XCTUnwrap(section.countryCodes.firstIndex(of: "US"))
        let caIndex = try XCTUnwrap(section.countryCodes.firstIndex(of: "CA"))
        let frIndex = try XCTUnwrap(section.countryCodes.firstIndex(of: "FR"))

        // FR -> US widens to the full address.
        section.country.select(index: usIndex)
        XCTAssertEqual(section.collectionMode, .autoCompletable)

        // US -> CA narrows to just the province.
        section.country.select(index: caIndex)
        XCTAssertEqual(section.collectionMode, .countryPostalAndState)

        // CA -> US widens back to the full address.
        section.country.select(index: usIndex)
        XCTAssertEqual(section.collectionMode, .autoCompletable)

        // US -> FR narrows all the way back to the base form.
        section.country.select(index: frIndex)
        XCTAssertEqual(section.collectionMode, .countryAndPostal())
    }

    func testNeverNarrowsBelowBase() throws {
        // A merchant collecting the full address keeps it, even for countries that need less for tax.
        let config = makeConfiguration(country: "US", address: .full)
        let form = makeForm(paymentMethod: .card, intent: makeCheckoutIntent(), config: config, specProvider: makeSpecProvider())
        let section = try XCTUnwrap(addressSection(in: form))
        XCTAssertEqual(section.collectionMode, .allWithAutocomplete)

        for country in ["CA", "FR"] {
            section.country.select(index: try XCTUnwrap(section.countryCodes.firstIndex(of: country)))
            XCTAssertEqual(section.collectionMode, .allWithAutocomplete)
        }
    }

    func testTaxForcesBillingAddressForLPM() throws {
        let form = makeForm(paymentMethod: .afterpayClearpay, intent: makeCheckoutIntent(), config: makeConfiguration(country: "US"), specProvider: makeSpecProvider())
        let section = try XCTUnwrap(addressSection(in: form), "Automatic tax should force a billing address section")
        XCTAssertEqual(section.collectionMode, .autoCompletable)
    }

}
