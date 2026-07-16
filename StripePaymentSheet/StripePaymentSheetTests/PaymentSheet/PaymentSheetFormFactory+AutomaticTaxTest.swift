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

    override func setUp() async throws {
        try await super.setUp()
        // Load the real form and address specs so every LPM builds its production form.
        await PaymentSheetLoader.loadMiscellaneousSingletons()
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
        config: PaymentSheet.Configuration
    ) -> PaymentMethodElement {
        let factory = PaymentSheetFormFactory(
            intent: intent,
            elementsSession: ._testCardValue(),
            configuration: .paymentElement(config),
            paymentMethod: .stripe(paymentMethod)
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
        // For every LPM PaymentSheet supports: when automatic tax is sourced from the billing address and
        // the merchant hasn't set `.automatic` collection to `.full`, the form must show a billing address
        // section that collects at least the minimum tax fields for its selected country. Every supported
        // LPM is expected to surface this section, so a missing section is a failure, not a skip.
        for pm in PaymentSheet.supportedPaymentMethods {
            let form = makeForm(paymentMethod: pm, intent: makeCheckoutIntent(), config: makeConfiguration(country: "US"))
            let section = try XCTUnwrap(
                addressSection(in: form),
                "\(pm.identifier) must collect a billing address section when tax is sourced from the billing address"
            )
            assertCollectsTaxFields(section, pm)
        }
    }

}
