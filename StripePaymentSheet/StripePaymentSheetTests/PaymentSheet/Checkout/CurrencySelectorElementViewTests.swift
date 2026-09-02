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

    func testUpdatesSwiftUILayoutWhenDetailsChangeHeight() async throws {
        // Given a currency selector in a SwiftUI view hierarchy
        let session = CheckoutTestHelpers.makeAdaptivePricingSession()
        let checkout = try await CheckoutController(
            configuration: CheckoutTestHelpers.makeCurrencySelectorConfiguration(apiResponse: session)
        )
        let element = try XCTUnwrap(checkout.getCurrencySelectorElement())
        let hostingController = UIHostingController(rootView: element.view)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 200))
        window.rootViewController = hostingController
        window.makeKeyAndVisible()
        layout(hostingController, in: window)
        let collapsedHeight = fittingHeight(of: hostingController)

        // When the customer expands the details
        currencySelector(in: element.uiView)?.expandableDetailView.toggleExpansion()
        let viewUpdate = expectation(description: "SwiftUI updates the representable")
        DispatchQueue.main.async {
            viewUpdate.fulfill()
        }
        await fulfillment(of: [viewUpdate], timeout: 1)
        layout(hostingController, in: window)

        // Then SwiftUI uses the currency selector's updated intrinsic height
        XCTAssertGreaterThan(fittingHeight(of: hostingController), collapsedHeight)
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

    private func currencySelector(in view: CurrencySelectorElementUIView) -> TwoOptionSelectorView? {
        return view.subviews
            .compactMap { ($0 as? UIStackView)?.arrangedSubviews.compactMap { $0 as? TwoOptionSelectorView }.first }
            .first
    }
}
