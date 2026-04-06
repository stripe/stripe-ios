//
//  CheckoutCurrencySelectorViewSnapshotTests.swift
//  StripePaymentSheetTests
//
//  Created by Nick Porter on 4/6/26.
//

import StripeCoreTestUtils
@testable @_spi(STP) import StripePayments
@testable @_spi(STP) @_spi(CheckoutSessionsPreview) import StripePaymentSheet
@_spi(STP) @testable import StripeUICore
import UIKit

@MainActor
final class CheckoutCurrencySelectorViewSnapshotTests: STPSnapshotTestCase {

    func testDefaultAppearance_localCurrencySelected() {
        let view = makeCurrencySelectorView(selectedCurrency: "gbp")
        verify(view)
    }

    func testDefaultAppearance_integrationCurrencySelected() {
        let view = makeCurrencySelectorView(selectedCurrency: "usd")
        verify(view)
    }

    func testDarkMode() {
        let view = makeCurrencySelectorView(selectedCurrency: "gbp")
        verify(view, darkMode: true)
    }

    func testCustomAppearance() {
        var appearance = Checkout.CurrencySelectorView.Appearance()
        appearance.cornerRadius = 16.0
        appearance.backgroundColor = .systemBlue.withAlphaComponent(0.1)
        appearance.selectedColor = .systemBlue
        appearance.selectedTextColor = .white
        appearance.unselectedTextColor = .systemBlue
        appearance.borderColor = .systemBlue
        appearance.captionColor = .systemBlue.withAlphaComponent(0.6)

        let view = makeCurrencySelectorView(selectedCurrency: "gbp", appearance: appearance)
        verify(view)
    }

    func testDisabledState() {
        let view = makeCurrencySelectorView(selectedCurrency: "gbp")
        view.isEnabled = false
        verify(view)
    }

    // MARK: - Helpers

    @MainActor
    private func makeCurrencySelectorView(
        selectedCurrency: String = "usd",
        appearance: Checkout.CurrencySelectorView.Appearance = .init()
    ) -> Checkout.CurrencySelectorView {
        let checkout = Checkout(clientSecret: "cs_test_123_secret_abc")
        let session = makeSession(selectedCurrency: selectedCurrency)
        checkout.updateSession(session)

        let view = Checkout.CurrencySelectorView(checkout: checkout, appearance: appearance)

        // Force Combine delivery and layout
        RunLoop.main.run(until: Date())
        view.setNeedsLayout()
        view.layoutIfNeeded()

        return view
    }

    private func verify(
        _ view: Checkout.CurrencySelectorView,
        darkMode: Bool = false,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        verifySelectorSnapshotView(view, darkMode: darkMode, file: file, line: line)
    }

    @MainActor
    private func makeSession(selectedCurrency: String) -> STPCheckoutSession {
        let json: [AnyHashable: Any] = [
            "session_id": "cs_test_123",
            "client_secret": "cs_test_123_secret_abc",
            "livemode": false,
            "mode": "payment",
            "status": "open",
            "payment_status": "unpaid",
            "payment_method_types": ["card"],
            "currency": selectedCurrency,
            "total_summary": [
                "subtotal": 1200,
                "total": 1200,
                "due": 1200,
            ],
            "developer_tool_context": [
                "adaptive_pricing": [
                    "active": true,
                ],
            ],
            "adaptive_pricing_info": [
                "integration_currency": "usd",
                "integration_amount": 1200,
                "active_presentment_currency": selectedCurrency,
                "local_currency_options": [
                    [
                        "currency": "gbp",
                        "amount": 1000,
                        "presentment_exchange_rate": "0.776917",
                        "conversion_markup_bps": 400,
                    ] as [AnyHashable: Any],
                ],
            ] as [AnyHashable: Any],
        ]

        return STPCheckoutSession.decodedObject(fromAPIResponse: json)!
    }
}
