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
import XCTest
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
        appearance.background = .systemBlue.withAlphaComponent(0.1)
        appearance.selectedBackground = .systemBlue
        appearance.selectedText = .white
        appearance.textSecondary = .systemBlue
        appearance.border = .systemBlue

        let view = await makeCurrencySelectorView(selectedCurrency: "gbp", appearance: appearance)
        verify(view)
    }

    func testCustomVerticalPadding_tall() async {
        var appearance = Checkout.CurrencySelectorView.Appearance()
        appearance.contentVerticalPadding = 13

        let view = await makeCurrencySelectorView(selectedCurrency: "gbp", appearance: appearance)
        verify(view)
    }

    func testCustomVerticalPadding_compact() async {
        var appearance = Checkout.CurrencySelectorView.Appearance()
        appearance.contentVerticalPadding = 1

        let view = await makeCurrencySelectorView(selectedCurrency: "gbp", appearance: appearance)
        verify(view)
    }

    func testCustomBorderWidth() async {
        var appearance = Checkout.CurrencySelectorView.Appearance()
        appearance.borderWidth = 2.0
        appearance.border = .systemBlue

        let view = await makeCurrencySelectorView(selectedCurrency: "gbp", appearance: appearance)
        verify(view)
    }

    func testSizeScaleFactor_large() async {
        var appearance = Checkout.CurrencySelectorView.Appearance()
        appearance.sizeScaleFactor = 1.3

        let view = await makeCurrencySelectorView(selectedCurrency: "gbp", appearance: appearance)
        verify(view)
    }

    func testCustomFont() async throws {
        var appearance = Checkout.CurrencySelectorView.Appearance()
        appearance.font = try XCTUnwrap(UIFont(name: "Courier", size: 14))

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

    func testLabelContentAmount() async {
        var appearance = Checkout.CurrencySelectorView.Appearance()
        appearance.labelContent = .amount

        let view = await makeCurrencySelectorView(selectedCurrency: "gbp", appearance: appearance)
        verify(view)
    }

    func testTextSecondaryClampsLowAlpha() async {
        var appearance = Checkout.CurrencySelectorView.Appearance()
        appearance.textSecondary = UIColor.red.withAlphaComponent(0.1)

        let view = await makeCurrencySelectorView(selectedCurrency: "gbp", appearance: appearance)
        verify(view)
    }

    func testTextSecondaryClampsFullyTransparent() async {
        var appearance = Checkout.CurrencySelectorView.Appearance()
        appearance.textSecondary = .clear

        let view = await makeCurrencySelectorView(selectedCurrency: "gbp", appearance: appearance)
        verify(view)
    }

    func testDetailExpanded_localCurrencySelected() async {
        let view = await makeCurrencySelectorView(selectedCurrency: "gbp")
        view.autosizeHeight(width: 320)
        expandDetail(in: view)
        verify(view)
    }

    func testDetailExpanded_darkMode() async {
        var appearance = Checkout.CurrencySelectorView.Appearance()
        appearance.textSecondary = .darkText

        let view = await makeCurrencySelectorView(selectedCurrency: "gbp", appearance: appearance)
        view.autosizeHeight(width: 320)
        expandDetail(in: view)
        verify(view, darkMode: true)
    }

    func testFullyCustomized() async {
        var appearance = Checkout.CurrencySelectorView.Appearance()
        appearance.contentVerticalPadding = 9
        appearance.cornerRadius = 22
        appearance.borderWidth = 1.5
        appearance.border = .systemPurple
        appearance.background = .systemPurple.withAlphaComponent(0.08)
        appearance.selectedBackground = .systemPurple
        appearance.font = .systemFont(ofSize: 15, weight: .bold)
        appearance.sizeScaleFactor = 1.1
        appearance.text = .label
        appearance.selectedText = .white
        appearance.textSecondary = .systemPurple

        let view = await makeCurrencySelectorView(selectedCurrency: "gbp", appearance: appearance)
        verify(view)
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
    private func expandDetail(in view: Checkout.CurrencySelectorView) {
        let selectorView = view.subviews
            .compactMap { ($0 as? UIStackView)?.arrangedSubviews.compactMap { $0 as? TwoOptionSelectorView }.first }
            .first
        selectorView?.toggleExpansion()
        view.setNeedsLayout()
        view.layoutIfNeeded()
    }

    @MainActor
    private func makeSession(selectedCurrency: String) -> STPCheckoutSession {
        CheckoutTestHelpers.makeAdaptivePricingSession(currency: selectedCurrency)
    }
}
