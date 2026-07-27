//
//  PaymentSheetLoaderAutomaticTaxTest.swift
//  StripePaymentSheetTests
//
//  Created by Nick Porter on 7/24/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

import XCTest

@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePayments
@testable@_spi(STP) import StripePaymentSheet
@testable@_spi(STP) import StripePaymentsTestUtils

@MainActor
final class PaymentSheetLoaderAutomaticTaxTest: XCTestCase {
    func testAutomaticTaxBillingAddressRequirements() {
        let completeAddresses = [
            ("US", makeCard()),
            ("PR", makeCard(state: nil, country: "PR")),
            ("CA", makeCard(line1: nil, city: nil, state: nil, postalCode: "not validated", country: "CA")),
            ("GB", makeCard(line1: nil, city: nil, state: nil, postalCode: "EC1A 1BB", country: "GB")),
            ("IN", makeCard(line1: nil, city: nil, state: nil, postalCode: "110001", country: "IN")),
            ("Other", makeCard(line1: nil, city: nil, state: nil, postalCode: nil, country: "fr")),
        ]
        let incompleteAddresses = [
            ("Missing country", makeCard(country: nil)),
            ("Empty country", makeCard(country: "")),
            ("Missing US line 1", makeCard(line1: nil)),
            ("Empty US line 1", makeCard(line1: "")),
            ("Missing US city", makeCard(city: nil)),
            ("Empty US city", makeCard(city: "")),
            ("Missing US state", makeCard(state: nil)),
            ("Empty US state", makeCard(state: "")),
            ("Missing US postal code", makeCard(postalCode: nil)),
            ("Empty US postal code", makeCard(postalCode: "")),
            ("Missing PR line 1", makeCard(line1: nil, state: nil, country: "PR")),
            ("Missing PR city", makeCard(city: nil, state: nil, country: "PR")),
            ("Missing PR postal code", makeCard(state: nil, postalCode: nil, country: "PR")),
            ("Missing CA postal code", makeCard(postalCode: nil, country: "CA")),
            ("Missing GB postal code", makeCard(postalCode: nil, country: "GB")),
            ("Missing IN postal code", makeCard(postalCode: nil, country: "IN")),
        ]

        for (name, paymentMethod) in completeAddresses {
            XCTAssertTrue(
                AutomaticTaxBillingAddressRequirements.areSatisfied(by: paymentMethod.billingDetails?.address),
                name
            )
        }
        for (name, paymentMethod) in incompleteAddresses {
            XCTAssertFalse(
                AutomaticTaxBillingAddressRequirements.areSatisfied(by: paymentMethod.billingDetails?.address),
                name
            )
        }
    }

    func testFiltersCheckoutAutomaticTaxFromBillingAndPreservesSessionSavedPaymentMethods() {
        let completeIntent = makeCheckoutIntent(paymentMethods: [makeCard()])
        let incompleteIntent = makeCheckoutIntent(paymentMethods: [makeCard(line1: nil)])

        XCTAssertEqual(filterCheckoutSavedPaymentMethods(intent: completeIntent).count, 1)
        XCTAssertTrue(filterCheckoutSavedPaymentMethods(intent: incompleteIntent).isEmpty)
        guard case .checkout(let session) = incompleteIntent else {
            return XCTFail("Expected a Checkout Session intent")
        }
        XCTAssertEqual(session.savedPaymentMethods.count, 1)
    }

    func testOnlyFiltersCheckoutAutomaticTaxFromBilling() {
        let incomplete = makeCard(line1: nil)
        let nonCheckoutIntents: [Intent] = [._testValue(), ._testSetupIntent()]
        let checkoutIntents = [
            makeCheckoutIntent(
                paymentMethods: [incomplete],
                automaticTaxEnabled: false,
                automaticTaxAddressSource: "session.billing"
            ),
            makeCheckoutIntent(
                paymentMethods: [incomplete],
                automaticTaxEnabled: true,
                automaticTaxAddressSource: "session.shipping"
            ),
        ]

        for intent in nonCheckoutIntents {
            XCTAssertEqual(
                PaymentSheetLoader.filterSavedPaymentMethods(
                    intent: intent,
                    elementsSession: ._testCardValue(),
                    configuration: PaymentSheet.Configuration(),
                    prefetchedSPMs: [incomplete],
                    loadTimings: .init()
                ).count,
                1
            )
        }
        for intent in checkoutIntents {
            XCTAssertEqual(filterCheckoutSavedPaymentMethods(intent: intent).count, 1)
        }
    }

    func testTaxAddressFilteringComposesWithAllowedCountryFiltering() {
        let completeUS = makeCard()
        let incompleteUS = makeCard(line1: nil)
        let completeCA = makeCard(postalCode: "M5V 3L9", country: "CA")
        let intent = makeCheckoutIntent(paymentMethods: [completeUS, incompleteUS, completeCA])
        var configuration = PaymentSheet.Configuration()
        configuration.billingDetailsCollectionConfiguration.allowedCountries = ["US"]

        let filtered = filterCheckoutSavedPaymentMethods(
            intent: intent,
            configuration: configuration
        )

        XCTAssertEqual(filtered.count, 1)
        XCTAssertEqual(filtered.first?.billingDetails?.address?.country, "US")
        XCTAssertNotNil(filtered.first?.billingDetails?.address?.line1)
    }

    private func filterCheckoutSavedPaymentMethods(
        intent: Intent,
        configuration: PaymentSheet.Configuration = .init()
    ) -> [STPPaymentMethod] {
        PaymentSheetLoader.filterSavedPaymentMethods(
            intent: intent,
            elementsSession: ._testCardValue(),
            configuration: configuration,
            prefetchedSPMs: nil,
            loadTimings: .init()
        )
    }

    private func makeCheckoutIntent(
        paymentMethods: [STPPaymentMethod],
        automaticTaxEnabled: Bool = true,
        automaticTaxAddressSource: String = "session.billing"
    ) -> Intent {
        let response = CheckoutTestHelpers.makeSession([
            "customer": [
                "id": "cus_123",
                "payment_methods": paymentMethods.map(\.allResponseFields),
            ],
            "tax_context": [
                "automatic_tax_enabled": automaticTaxEnabled,
                "automatic_tax_address_source": automaticTaxAddressSource,
            ],
        ])
        return .checkout(response.makePublicSession())
    }

    private func makeCard(
        line1: String? = "123 Main St",
        city: String? = "San Francisco",
        state: String? = "CA",
        postalCode: String? = "94111",
        country: String? = "US"
    ) -> STPPaymentMethod {
        return ._testCard(
            line1: line1,
            city: city,
            state: state,
            postalCode: postalCode,
            countryCode: country
        )
    }
}
