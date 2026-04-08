//
//  CheckoutCurrencySelectorElementSnapshotTests.swift
//  StripePaymentSheetTests
//
//  Created by Nick Porter on 4/8/26.
//

import StripeCoreTestUtils
@testable @_spi(STP) import StripePayments
@testable @_spi(STP) @_spi(CheckoutSessionsPreview) import StripePaymentSheet
@_spi(STP) @testable import StripeUICore
import SwiftUI
import UIKit
import XCTest

// ☠️ WARNING: These snapshots do not have capsule corners on iOS 26 - this is a snapshot-test-only-bug and does not repro on simulator/device.
@available(iOS 15.0, *)
@MainActor
// @iOS26
final class CheckoutCurrencySelectorElementSnapshotTests: STPSnapshotTestCase {

    func testDefaultAppearance_localCurrencySelected() {
        let view = makeCurrencySelectorElement(selectedCurrency: "gbp")
        verify(view)
    }

    func testDefaultAppearance_integrationCurrencySelected() {
        let view = makeCurrencySelectorElement(selectedCurrency: "usd")
        verify(view)
    }

    func testDarkMode() {
        let view = makeCurrencySelectorElement(selectedCurrency: "gbp")
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

        let view = makeCurrencySelectorElement(selectedCurrency: "gbp", appearance: appearance)
        verify(view)
    }

    func testDisabledState() {
        let view = makeCurrencySelectorElement(selectedCurrency: "gbp", disabled: true)
        verify(view)
    }

    // MARK: - Helpers

    @MainActor
    private func makeCurrencySelectorElement(
        selectedCurrency: String = "usd",
        appearance: Checkout.CurrencySelectorView.Appearance = .init(),
        disabled: Bool = false
    ) -> some View {
        let session = CheckoutTestHelpers.makeAdaptivePricingSession(currency: selectedCurrency)
        let checkout = Checkout(clientSecret: "cs_test_123_secret_abc", session: session)

        return Checkout.CurrencySelectorElement(checkout: checkout, appearance: appearance)
            .disabled(disabled)
            .frame(width: 320)
            .ignoresSafeArea()
    }

    private func verify(
        _ swiftUIView: some View,
        darkMode: Bool = false,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let vc = UIHostingController(rootView: swiftUIView)

        // Use a tall window so SwiftUI has room to lay out, then size to fit content
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 200))
        window.overrideUserInterfaceStyle = darkMode ? .dark : .light
        window.rootViewController = vc
        window.makeKeyAndVisible()

        // Force Combine delivery and layout
        RunLoop.main.run(until: Date())
        vc.view.setNeedsLayout()
        vc.view.layoutIfNeeded()

        vc.view.frame = CGRect(origin: .zero, size: CGSize(width: 320, height: 57))
        vc.view.layoutIfNeeded()

        STPSnapshotVerifyView(vc.view, file: file, line: line)
    }
}
