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
        try await verify(view)
    }

    func testDarkMode() async throws {
        let view = try await makeCurrencySelectorElement(selectedCurrency: "gbp")
        try await verify(view, darkMode: true)
    }

    func testDetailExpanded() async throws {
        let element = try await makeCurrencySelectorElement(selectedCurrency: "gbp")
        try await verify(element, expanded: true)
    }

    func testDetailExpanded_darkMode() async throws {
        let element = try await makeCurrencySelectorElement(selectedCurrency: "gbp")
        try await verify(element, darkMode: true, expanded: true)
    }

    // MARK: - Helpers

    @MainActor
    private func makeCurrencySelectorElement(
        selectedCurrency: String = "usd",
        appearance: CurrencySelectorElement.Appearance = .init()
    ) async throws -> CurrencySelectorElement {
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

        return try XCTUnwrap(checkout.getCurrencySelectorElement())
    }

    private func verify(
        _ element: CurrencySelectorElement,
        darkMode: Bool = false,
        expanded: Bool = false,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async throws {
        let verticalPadding: CGFloat = 8
        let vc = UIHostingController(rootView: element.view.frame(width: 320))
        vc.view.layoutMargins = .zero
        vc.view.preservesSuperviewLayoutMargins = false
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 200))
        window.overrideUserInterfaceStyle = darkMode ? .dark : .light
        window.rootViewController = vc
        window.isHidden = false
        vc.view.setNeedsLayout()
        vc.view.layoutIfNeeded()

        if expanded {
            let selector = try XCTUnwrap(element.uiView.subviews
                .compactMap { ($0 as? UIStackView)?.arrangedSubviews.compactMap { $0 as? TwoOptionSelectorView }.first }
                .first)
            UIView.performWithoutAnimation {
                selector.expandableDetailView.toggleExpansion()
            }
            let viewUpdate = expectation(description: "SwiftUI updates the expanded selector")
            DispatchQueue.main.async {
                viewUpdate.fulfill()
            }
            await fulfillment(of: [viewUpdate], timeout: 1)
            vc.view.setNeedsLayout()
            vc.view.layoutIfNeeded()
        }

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
