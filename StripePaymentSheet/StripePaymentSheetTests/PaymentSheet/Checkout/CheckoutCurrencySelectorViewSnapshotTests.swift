//
//  CheckoutCurrencySelectorViewSnapshotTests.swift
//  StripePaymentSheetTests
//
//  Created by Nick Porter on 4/6/26.
//

import StripeCoreTestUtils
@testable @_spi(STP) import StripePayments
@testable @_spi(STP) import StripePaymentSheet
@_spi(STP) @testable import StripeUICore
import UIKit
// ☠️ WARNING: These snapshots do not have capsule corners on iOS 26 - this is a snapshot-test-only-bug and does not repro on simulator/device.
@MainActor
// @iOS26
final class CheckoutCurrencySelectorViewSnapshotTests: STPSnapshotTestCase {

    func testDefaultAppearance_localCurrencySelected() async {
        let view = await makeCurrencySelectorView(selectedCurrency: "gbp")
        verify(view)
    }

    func testDefaultAppearance_integrationCurrencySelected() async {
        let view = await makeCurrencySelectorView(selectedCurrency: "usd")
        verify(view)
    }

    func testDarkMode() async {
        let view = await makeCurrencySelectorView(selectedCurrency: "gbp")
        verify(view, darkMode: true)
    }

    func testCustomAppearance() async {
        var appearance = Checkout.CurrencySelectorView.Appearance()
        appearance.cornerRadius = 16.0
        appearance.titleFont = .systemFont(ofSize: 40, weight: .bold)
        appearance.backgroundColor = .systemBlue.withAlphaComponent(0.1)
        appearance.selectedColor = .systemBlue
        appearance.selectedTextColor = .white
        appearance.unselectedTextColor = .systemBlue
        appearance.borderColor = .systemBlue
        appearance.captionColor = .systemBlue.withAlphaComponent(0.6)

        let view = await makeCurrencySelectorView(selectedCurrency: "gbp", appearance: appearance)
        verify(view)
    }

    func testDisabledState() async {
        let view = await makeCurrencySelectorView(selectedCurrency: "gbp")
        view.isEnabled = false
        verify(view)
    }

    func testErrorState() async {
        let view = await makeCurrencySelectorView(selectedCurrency: "gbp")
        view.showError("Something went wrong. Please try again.")
        view.setNeedsLayout()
        view.layoutIfNeeded()
        verify(view)
    }

    func testErrorState_darkMode() async {
        let view = await makeCurrencySelectorView(selectedCurrency: "gbp")
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
    ) async -> Checkout.CurrencySelectorView {
        let session = makeSession(selectedCurrency: selectedCurrency)
        let checkout = await Checkout(clientSecret: "cs_test_123_secret_abc", session: session)

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
        width: CGFloat = 320,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        view.autosizeHeight(width: width)

        let window = UIWindow(frame: CGRect(origin: .zero, size: view.frame.size))
        window.overrideUserInterfaceStyle = darkMode ? .dark : .light
        window.isHidden = false
        window.addAndPinSubview(view)
        window.layoutIfNeeded()

        STPSnapshotVerifyView(view, file: file, line: line)
    }

    @MainActor
    private func makeSession(selectedCurrency: String) -> STPCheckoutSession {
        CheckoutTestHelpers.makeAdaptivePricingSession(currency: selectedCurrency)
    }
}
