//
//  CheckoutCurrencySelectorElementSnapshotTests.swift
//  StripePaymentSheetTests
//
//  Created by Nick Porter on 4/8/26.
//

import StripeCoreTestUtils
@testable @_spi(STP) import StripePayments
@testable @_spi(STP) import StripePaymentSheet
@_spi(STP) @testable import StripeUICore
import SwiftUI
import UIKit
import XCTest

// ☠️ WARNING: These snapshots do not have capsule corners on iOS 26 - this is a snapshot-test-only-bug and does not repro on simulator/device.
@available(iOS 15.0, *)
@MainActor
// @iOS26
final class CheckoutCurrencySelectorElementSnapshotTests: STPSnapshotTestCase {

    func testDefaultAppearance() async {
        let view = await makeCurrencySelectorElement(selectedCurrency: "gbp")
        verify(view)
    }

    func testDarkMode() async {
        let view = await makeCurrencySelectorElement(selectedCurrency: "gbp")
        verify(view, darkMode: true)
    }

    // MARK: - Helpers

    @MainActor
    private func makeCurrencySelectorElement(
        selectedCurrency: String = "usd",
        appearance: Checkout.CurrencySelectorView.Appearance = .init(),
        disabled: Bool = false
    ) async -> some View {
        let session = CheckoutTestHelpers.makeAdaptivePricingSession(currency: selectedCurrency)
        let checkout = await Checkout(clientSecret: "cs_test_123_secret_abc", session: session)

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
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 200))
        window.overrideUserInterfaceStyle = darkMode ? .dark : .light
        window.rootViewController = vc
        window.makeKeyAndVisible()
        vc.view.frame = CGRect(origin: .zero, size: CGSize(width: 320, height: 57))

        STPSnapshotVerifyView(vc.view, file: file, line: line)
    }
}
