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

    func testVisibilityUpdatesWithAdaptivePricingAvailability() async throws {
        // Given a currency selector without Adaptive Pricing data
        let checkout = try await Checkout(configuration: CheckoutTestHelpers.makeConfiguration())
        let element = checkout.getCurrencySelectorElement()
        let hostingController = UIHostingController(rootView: try XCTUnwrap(element).view)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 200))
        window.rootViewController = hostingController
        window.makeKeyAndVisible()
        let hiddenHeight = fittingHeight(of: hostingController)

        // When Adaptive Pricing becomes available
        try await checkout.commitSession(CheckoutTestHelpers.makeAdaptivePricingSession())

        // Then the selector appears in the SwiftUI layout
        try await waitUntil {
            self.layout(hostingController, in: window)
            return self.fittingHeight(of: hostingController) > hiddenHeight + 1
        }

        // When Adaptive Pricing becomes unavailable again
        try await checkout.commitSession(
            CheckoutTestHelpers.makeAdaptivePricingSession(adaptivePricingActive: false)
        )

        // Then the selector is removed from the SwiftUI layout
        try await waitUntil {
            self.layout(hostingController, in: window)
            return abs(self.fittingHeight(of: hostingController) - hiddenHeight) < 1
        }
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

    private func waitUntil(
        timeout: TimeInterval = 2,
        file: StaticString = #filePath,
        line: UInt = #line,
        _ condition: () -> Bool
    ) async throws {
        let deadline = Date().addingTimeInterval(timeout)
        while !condition() {
            if Date() >= deadline {
                XCTFail("Condition not met within \(timeout) seconds", file: file, line: line)
                throw CurrencySelectorElementViewTestTimeoutError()
            }
            try await Task.sleep(nanoseconds: 10_000_000)
        }
    }
}

private struct CurrencySelectorElementViewTestTimeoutError: Error {}
