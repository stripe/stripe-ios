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
        var configuration = CheckoutController.Configuration(clientSecret: "cs_test_123_secret_abc", returnURL: "stripe-ios-test://checkout-return")
        var currencySelectorConfiguration = CurrencySelectorElement.Configuration()
        currencySelectorConfiguration.appearance = appearance
        configuration.currencySelectorElement = currencySelectorConfiguration
        let checkout = try await CheckoutController(
            configuration: CheckoutTestHelpers.makeCurrencySelectorConfiguration(
                apiResponse: session,
                configuration: configuration
            )
        )

        return try XCTUnwrap(checkout.getCurrencySelectorElement()).view
            .disabled(disabled)
            .frame(width: 320)
    }

    private func verify(
        _ swiftUIView: some View,
        darkMode: Bool = false,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let verticalPadding: CGFloat = 8
        let vc = UIHostingController(rootView: swiftUIView)
        vc.view.layoutMargins = .zero
        vc.view.preservesSuperviewLayoutMargins = false
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 200))
        window.overrideUserInterfaceStyle = darkMode ? .dark : .light
        window.rootViewController = vc
        window.isHidden = false
        vc.view.setNeedsLayout()
        vc.view.layoutIfNeeded()

        guard let renderedView = vc.view.subviews.first else {
            XCTFail("SwiftUI content did not render", file: file, line: line)
            return
        }

        let snapshotVC = UIViewController()
        snapshotVC.view.frame = CGRect(
            x: 0,
            y: 0,
            width: renderedView.bounds.width,
            height: renderedView.bounds.height + verticalPadding * 2
        )
        snapshotVC.view.backgroundColor = .systemBackground
        renderedView.removeFromSuperview()
        renderedView.translatesAutoresizingMaskIntoConstraints = true
        snapshotVC.view.addSubview(renderedView)
        renderedView.frame.origin = CGPoint(x: 0, y: verticalPadding)
        window.frame = snapshotVC.view.bounds
        window.rootViewController = snapshotVC
        snapshotVC.view.layoutIfNeeded()

        STPSnapshotVerifyView(snapshotVC.view, file: file, line: line)
    }
}
