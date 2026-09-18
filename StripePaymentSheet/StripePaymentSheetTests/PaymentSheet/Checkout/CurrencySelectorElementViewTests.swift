//
//  CurrencySelectorElementViewTests.swift
//  StripePaymentSheetTests
//
//  Created by Nick Porter on 7/22/26.
//

@testable @_spi(STP) import StripePaymentSheet
import SwiftUI
import UIKit
import XCTest

@MainActor
final class CurrencySelectorElementViewTests: XCTestCase {

    func testDisplaysAdaptivePricingSelector() async throws {
        // Given a currency selector with Adaptive Pricing data
        let session = CheckoutTestHelpers.makeAdaptivePricingSession()
        let checkout = try await CheckoutController(
            configuration: CheckoutTestHelpers.makeCurrencySelectorConfiguration(apiResponse: session)
        )
        let element = checkout.getCurrencySelectorElement()
        let hostingController = UIHostingController(rootView: try XCTUnwrap(element).view)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 200))
        window.rootViewController = hostingController
        window.makeKeyAndVisible()
        layout(hostingController, in: window)

        // Then it participates in the SwiftUI layout
        XCTAssertGreaterThan(fittingHeight(of: hostingController), 1)
    }

    func testSwiftUIViewFitsMultilineCaption() async throws {
        // Given a narrow SwiftUI host and the selector's largest supported caption font
        let session = CheckoutTestHelpers.makeAdaptivePricingSession(currency: "gbp")
        var configuration = CheckoutController.Configuration(clientSecret: "cs_test_123_secret_abc", returnURL: "stripe-ios-test://checkout-return")
        var selectorConfiguration = CurrencySelectorElement.Configuration()
        selectorConfiguration.appearance.sizeScaleFactor = 2
        configuration.currencySelectorElement = selectorConfiguration
        let checkout = try await CheckoutController(
            configuration: CheckoutTestHelpers.makeCurrencySelectorConfiguration(apiResponse: session, configuration: configuration)
        )
        let element = try XCTUnwrap(checkout.getCurrencySelectorElement())
        let hostingController = UIHostingController(rootView: element.view)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 300))
        window.rootViewController = hostingController
        window.makeKeyAndVisible()
        defer { window.isHidden = true }

        let caption = try captionLabel(in: element)
        for width: CGFloat in [320, 250, 400] {
            // When SwiftUI measures the selector at a new width
            window.frame.size.width = width
            hostingController.view.frame = window.bounds
            layout(hostingController, in: window)
            let requiredHeight = caption.sizeThatFits(CGSize(width: caption.bounds.width, height: .greatestFiniteMagnitude)).height

            // Then the full multiline caption, including Show details, fits inside the element
            XCTAssertGreaterThan(requiredHeight, caption.font.lineHeight + 1)
            XCTAssertGreaterThanOrEqual(caption.bounds.height, requiredHeight - 1)
            XCTAssertLessThanOrEqual(caption.convert(caption.bounds, to: element.uiView).maxY, element.uiView.bounds.height + 1)
        }
    }

    private func captionLabel(in element: CurrencySelectorElement) throws -> TappableAttributedLabel {
        let selector = try XCTUnwrap(element.uiView.subviews.compactMap {
            ($0 as? UIStackView)?.arrangedSubviews.compactMap { $0 as? TwoOptionSelectorView }.first
        }.first)
        return try XCTUnwrap(selector.expandableDetailView.subviews.compactMap { $0 as? TappableAttributedLabel }.first)
    }

    private func layout(_ viewController: UIViewController, in window: UIWindow) {
        window.setNeedsLayout()
        window.layoutIfNeeded()
        viewController.view.setNeedsLayout()
        viewController.view.layoutIfNeeded()
    }

    private func fittingHeight(of hostingController: UIHostingController<CurrencySelectorElementView>) -> CGFloat {
        hostingController.sizeThatFits(in: CGSize(width: 320, height: 200)).height
    }

}
