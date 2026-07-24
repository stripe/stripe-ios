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
@MainActor
// @iOS26
final class CheckoutCurrencySelectorElementSnapshotTests: STPSnapshotTestCase {

    func testDefaultAppearance() async throws {
        let view = try await makeCurrencySelectorElement(selectedCurrency: "gbp")
        verify(view)
    }

    func testDarkMode() async throws {
        let view = try await makeCurrencySelectorElement(selectedCurrency: "gbp")
        verify(view, darkMode: true)
    }

    // MARK: - Helpers

    @MainActor
    private func makeCurrencySelectorElement(
        selectedCurrency: String = "usd",
        appearance: CurrencySelectorElement.Appearance = .init(),
        disabled: Bool = false
    ) async throws -> some View {
        let session = CheckoutTestHelpers.makeAdaptivePricingSession(currency: selectedCurrency)
        var configuration = Checkout.Configuration(clientSecret: "cs_test_123_secret_abc")
        configuration.currencySelectorElement.appearance = appearance
        let checkout = try await Checkout(
            configuration: CheckoutTestHelpers.makeConfiguration(
                apiResponse: session,
                configuration: configuration
            )
        )

        return checkout.getCurrencySelectorElement().view
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
