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

    override func setUp() {
        super.setUp()
        // Load form specs so spec-driven LPMs (FPX, EPS, etc.) build a real form.
        let expectation = expectation(description: "Load form specs")
        FormSpecProvider.shared.load { _ in expectation.fulfill() }
        waitForExpectations(timeout: 5)
    }

    private func makeSpecProvider() -> AddressSpecProvider {
        let provider = AddressSpecProvider()
        provider.addressSpecs = [
            "US": AddressSpec(format: "ACSZ", require: "ACSZ", cityNameType: .city, stateNameType: .state, zip: "", zipNameType: .zip, subKeys: ["CA", "NY"], subLabels: ["California", "New York"]),
            "CA": AddressSpec(format: "ACSZ", require: "ACSZ", cityNameType: .city, stateNameType: .province, zip: "", zipNameType: .postal_code, subKeys: ["ON", "BC"], subLabels: ["Ontario", "British Columbia"]),
            "IN": AddressSpec(format: "ACSZ", require: "ACSZ", cityNameType: .city, stateNameType: .state, zip: "", zipNameType: .zip, subKeys: ["MH", "KA"], subLabels: ["Maharashtra", "Karnataka"]),
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

    /// Asserts `section` collects at least the billing fields tax needs for its currently-selected country.
    private func assertCollectsTaxFields(_ section: AddressSectionElement, _ pm: STPPaymentMethodType, file: StaticString = #filePath, line: UInt = #line) {
        let country = section.selectedCountryCode
        switch CountryTaxRequirement.fieldsToCollectByCountry[country] {
        case .all:
            // Full address required → line1 (or its autocomplete stand-in) must be present.
            XCTAssertTrue(section.line1 != nil || section.autoCompleteLine != nil,
                          "\(pm.identifier) must collect line1 for tax in \(country)", file: file, line: line)
        case .countryAndPostal:
            XCTAssertNotNil(section.postalCode, "\(pm.identifier) must collect postal for tax in \(country)", file: file, line: line)
        case .country, .none:
            break // Country-only requirement; the country dropdown is always present.
        }
    }

    func testAllSupportedLPMsCollectMinimumTaxFieldsWithAutomaticTax() throws {
        // For every LPM PaymentSheet supports: when automatic tax is sourced from the billing address
        // and the merchant hasn't set `.automatic` collection to `.full`, any billing address section
        // the form shows must collect the minimum tax fields for its selected country.
        for pm in PaymentSheet.supportedPaymentMethods {
            let form = makeForm(paymentMethod: pm, intent: makeCheckoutIntent(), config: makeConfiguration(country: "US"), specProvider: makeSpecProvider())
            guard let section = addressSection(in: form) else { continue } // LPM doesn't collect a billing address in-form.
            assertCollectsTaxFields(section, pm)
        }
    }

}
