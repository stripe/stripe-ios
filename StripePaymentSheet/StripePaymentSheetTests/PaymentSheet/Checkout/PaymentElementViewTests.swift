//
//  PaymentElementViewTests.swift
//  StripePaymentSheetTests
//
//  Created by Yuki Tokuhiro on 7/13/26.
//

@testable @_spi(STP) import StripePaymentSheet
import SwiftUI
import UIKit
import XCTest

@MainActor
final class PaymentElementViewTests: XCTestCase {

    func testSwiftUIViewUpdatesHeightWhenEmbeddedPaymentElementHeightChanges() async throws {
        var configuration = Checkout.Configuration(clientSecret: "cs_test_123_secret_abc")
        configuration.paymentElement.displaysMandateText = true
        let checkout = try await Checkout(configuration: CheckoutTestHelpers.makeConfiguration(configuration: configuration))
        let paymentElement = checkout.getPaymentElement()

        let hostingController = UIHostingController(
            rootView: paymentElement.view.transaction { $0.animation = nil }
        )
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 800))
        window.rootViewController = hostingController
        window.makeKeyAndVisible()
        hostingController.view.frame = window.bounds

        layout(hostingController)
        try await waitUntil {
            layout(hostingController)
            return paymentElement.uiView.frame.height > 0
        }
        let initialHeight = paymentElement.uiView.frame.height

        paymentElement.embeddedPaymentElement.testHeightChange()

        try await waitUntil {
            layout(hostingController)
            return abs(paymentElement.uiView.frame.height - initialHeight) > 1
        }
    }

    private func layout(_ viewController: UIViewController) {
        viewController.view.setNeedsLayout()
        viewController.view.layoutIfNeeded()
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
                throw PaymentElementViewTestTimeoutError()
            }
            try await Task.sleep(nanoseconds: 10_000_000)
        }
    }
}

private struct PaymentElementViewTestTimeoutError: Error {}
