//
//  EmbeddedViewRepresentableSnapshotTest.swift
//  StripePaymentSheetTests
//
//  Created by Nick Porter on 1/31/25.
//

import StripeCoreTestUtils
@testable import StripePayments
@testable import StripePaymentSheet
@testable import StripePaymentsTestUtils
@testable import StripeUICore
import SwiftUI
import XCTest

@MainActor
class EmbeddedViewRepresentableSnapshotTest: STPSnapshotTestCase {

    func testEmbeddedPaymentElementView() async throws {
        let intentConfig = EmbeddedPaymentElement.IntentConfiguration(
            mode: .payment(amount: 1000, currency: "USD"),
            paymentMethodTypes: ["card", "cashapp", "us_bank_account", "link", "apple_pay", "afterpay_clearpay"]
        ) { _, _ in
            // In these tests, we don't call confirm, so pass an empty handler.
            return ""
        }

        var config = EmbeddedPaymentElement.Configuration._testValue_MostPermissive(isApplePayEnabled: false)
        config.paymentMethodOrder = intentConfig.paymentMethodTypes
        config.apiClient = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)

        // Create our SwiftUI view
        let viewModel = EmbeddedPaymentElementViewModel()
        let swiftUIView = EmbeddedPaymentElementView(viewModel: viewModel)
                                            .animation(nil) // Disable animations for testing
        try await viewModel.load(intentConfiguration: intentConfig, configuration: config)

        // Embed `swiftUIView` in a UIWindow for rendering
        let hostingVC = makeWindowWithEmbeddedView(swiftUIView)
        viewModel.embeddedPaymentElement?.presentingViewController = hostingVC

        // Assume the hostingVC only has 1 subview...
        XCTAssertFalse(hostingVC.view.subviews.isEmpty)
        let subview = hostingVC.view.subviews[0]

        verify(subview, identifier: "before_height_change")

        // Simulate a height change
        viewModel.testHeightChange()

        verify(subview, identifier: "after_height_change")

        // We need to set presentingViewController during testing since the UIApplication.shared.window is nil during testing
        viewModel.embeddedPaymentElement?.presentingViewController = hostingVC

        // Toggle height back to original state
        viewModel.testHeightChange()

        verify(subview, identifier: "after_second_height_change")

        viewModel.embeddedPaymentElement?.presentingViewController = hostingVC

        // Toggle height back to original state
        viewModel.testHeightChange()

        verify(subview, identifier: "after_third_height_change")
    }

    // MARK: - Helpers

    private func createEmbeddedPaymentElement(
        intentConfiguration: EmbeddedPaymentElement.IntentConfiguration,
        configuration: EmbeddedPaymentElement.Configuration
    ) async throws -> EmbeddedPaymentElement {
        return try await EmbeddedPaymentElement.create(
            intentConfiguration: intentConfiguration,
            configuration: configuration
        )
    }

    /// Wraps a SwiftUI `EmbeddedViewRepresentable` in a UIWindow to ensure
    /// the SwiftUI content is actually rendered prior to snapshotting.
    private func makeWindowWithEmbeddedView(
        _ swiftUIView: some View,
        width: CGFloat = 320,
        height: CGFloat = 800
    ) -> UIViewController {
        // Create a UIHostingController for a SwiftUI view.
        let hostingController = UIHostingController(rootView: swiftUIView)
        hostingController.view.layoutMargins = .zero
        hostingController.view.preservesSuperviewLayoutMargins = false

        // Create a UIWindow & set its rootViewController to our hosting controller.
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: width, height: height))
        window.rootViewController = hostingController
        window.isHidden = false

        // Force layout so SwiftUI draws its content.
        hostingController.view.setNeedsLayout()
        hostingController.view.layoutIfNeeded()

        return hostingController
    }

    func verify(
        _ view: UIView,
        identifier: String? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        STPSnapshotVerifyView(view, identifier: identifier, file: file, line: line)
    }
}
