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
// ☠️ WARNING: These snapshots do not have capsule corners on iOS 26 - this is a snapshot-test-only-bug and does not repro on simulator/device.
@MainActor
// @iOS26
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

    func testErrorState() {
        let view = makeCurrencySelectorView(selectedCurrency: "gbp")
        view.showError("Something went wrong. Please try again.")
        view.setNeedsLayout()
        view.layoutIfNeeded()
        verify(view)
    }

    func testErrorState_darkMode() {
        let view = makeCurrencySelectorView(selectedCurrency: "gbp")
        view.showError("Something went wrong. Please try again.")
        view.setNeedsLayout()
        view.layoutIfNeeded()
        verify(view, darkMode: true)
    }

    // MARK: - Helpers

    @MainActor
    private func makeCurrencySelectorView(
        selectedCurrency: String = "usd",
        appearance: Checkout.CurrencySelectorView.Appearance = .init()
    ) -> Checkout.CurrencySelectorView {
        let checkout = Checkout(clientSecret: "cs_test_123_secret_abc", session: CheckoutTestHelpers.makeOpenSession())
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
        CheckoutTestHelpers.makeAdaptivePricingSession(currency: selectedCurrency)
    }
}
