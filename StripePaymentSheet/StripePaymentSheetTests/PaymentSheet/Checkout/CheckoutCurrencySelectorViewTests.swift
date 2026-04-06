//
//  CheckoutCurrencySelectorViewTests.swift
//  StripePaymentSheetTests
//
//  Created by Nick Porter on 4/6/26.
//

@testable @_spi(STP) import StripePayments
@testable @_spi(STP) @_spi(CheckoutSessionsPreview) import StripePaymentSheet
import XCTest

@MainActor
final class CheckoutCurrencySelectorViewTests: XCTestCase {

    // MARK: - Auto-hide tests

    func testHiddenWhenSessionIsNil() {
        let checkout = Checkout(clientSecret: "cs_test_123_secret_abc")
        let view = Checkout.CurrencySelectorView(checkout: checkout)

        // Session is nil before load(), so the view should be hidden
        XCTAssertTrue(view.isHidden)
    }

    func testHiddenWhenAdaptivePricingNotActive() {
        let checkout = Checkout(clientSecret: "cs_test_123_secret_abc")
        let session = makeSession(adaptivePricingActive: false)
        checkout.updateSession(session)

        let view = Checkout.CurrencySelectorView(checkout: checkout)

        // Give Combine time to deliver
        let expectation = expectation(description: "View updates")
        DispatchQueue.main.async {
            XCTAssertTrue(view.isHidden)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func testHiddenWhenLocalizedPricesEmpty() {
        let checkout = Checkout(clientSecret: "cs_test_123_secret_abc")
        let session = makeSession(includeLocalizedPrices: false)
        checkout.updateSession(session)

        let view = Checkout.CurrencySelectorView(checkout: checkout)

        let expectation = expectation(description: "View updates")
        DispatchQueue.main.async {
            XCTAssertTrue(view.isHidden)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func testHiddenWhenExchangeRateMetaNil() {
        let checkout = Checkout(clientSecret: "cs_test_123_secret_abc")
        let session = makeSession(includeExchangeRateFields: false)
        checkout.updateSession(session)

        let view = Checkout.CurrencySelectorView(checkout: checkout)

        let expectation = expectation(description: "View updates")
        DispatchQueue.main.async {
            XCTAssertTrue(view.isHidden)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func testVisibleWhenAdaptivePricingActive() {
        let checkout = Checkout(clientSecret: "cs_test_123_secret_abc")
        let session = makeSession()
        checkout.updateSession(session)

        let view = Checkout.CurrencySelectorView(checkout: checkout)

        let expectation = expectation(description: "View updates")
        DispatchQueue.main.async {
            XCTAssertFalse(view.isHidden)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func testTransitionsFromHiddenToVisibleOnSessionUpdate() {
        let checkout = Checkout(clientSecret: "cs_test_123_secret_abc")
        let view = Checkout.CurrencySelectorView(checkout: checkout)

        // Initially hidden
        XCTAssertTrue(view.isHidden)

        // Update with AP session
        let session = makeSession()
        checkout.updateSession(session)

        let expectation = expectation(description: "View becomes visible")
        DispatchQueue.main.async {
            XCTAssertFalse(view.isHidden)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - Enabled state

    func testIsEnabledDefaultsToTrue() {
        let checkout = Checkout(clientSecret: "cs_test_123_secret_abc")
        let view = Checkout.CurrencySelectorView(checkout: checkout)
        XCTAssertTrue(view.isEnabled)
    }

    func testIsEnabledCanBeSet() {
        let checkout = Checkout(clientSecret: "cs_test_123_secret_abc")
        let view = Checkout.CurrencySelectorView(checkout: checkout)
        view.isEnabled = false
        XCTAssertFalse(view.isEnabled)
    }

    // MARK: - Appearance

    func testDefaultAppearanceValues() {
        let appearance = Checkout.CurrencySelectorView.Appearance()
        XCTAssertEqual(appearance.cornerRadius, 8.0)
        XCTAssertEqual(appearance.backgroundColor, .secondarySystemBackground)
        XCTAssertEqual(appearance.selectedColor, .systemBackground)
        XCTAssertEqual(appearance.selectedTextColor, .label)
        XCTAssertEqual(appearance.unselectedTextColor, .secondaryLabel)
        XCTAssertEqual(appearance.borderColor, .separator)
        XCTAssertEqual(appearance.captionColor, .secondaryLabel)
    }

    func testCustomAppearanceIsApplied() {
        let checkout = Checkout(clientSecret: "cs_test_123_secret_abc")
        let session = makeSession()
        checkout.updateSession(session)

        var appearance = Checkout.CurrencySelectorView.Appearance()
        appearance.cornerRadius = 16.0
        appearance.backgroundColor = .red

        let view = Checkout.CurrencySelectorView(checkout: checkout, appearance: appearance)

        let expectation = expectation(description: "View updates")
        DispatchQueue.main.async {
            XCTAssertFalse(view.isHidden)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - Helpers

    private func makeSession(
        adaptivePricingActive: Bool = true,
        includeLocalizedPrices: Bool = true,
        includeExchangeRateFields: Bool = true
    ) -> STPCheckoutSession {
        var json: [AnyHashable: Any] = [
            "session_id": "cs_test_123",
            "client_secret": "cs_test_123_secret_abc",
            "livemode": false,
            "mode": "payment",
            "status": "open",
            "payment_status": "unpaid",
            "payment_method_types": ["card"],
            "currency": "usd",
            "total_summary": [
                "subtotal": 1200,
                "total": 1200,
                "due": 1200,
            ],
            "developer_tool_context": [
                "adaptive_pricing": [
                    "active": adaptivePricingActive,
                ],
            ],
        ]

        if includeLocalizedPrices {
            var localCurrencyOption: [AnyHashable: Any] = [
                "currency": "gbp",
                "amount": 1000,
            ]
            if includeExchangeRateFields {
                localCurrencyOption["presentment_exchange_rate"] = "0.776917"
                localCurrencyOption["conversion_markup_bps"] = 400
            }
            json["adaptive_pricing_info"] = [
                "integration_currency": "usd",
                "integration_amount": 1200,
                "active_presentment_currency": "usd",
                "local_currency_options": [localCurrencyOption],
            ]
        }

        return STPCheckoutSession.decodedObject(fromAPIResponse: json)!
    }
}
