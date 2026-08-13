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
        let checkout = try await Checkout(
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
