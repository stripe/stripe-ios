//
//  SheetDismissalAnalyticsTests.swift
//  StripePaymentSheetTests
//
//  Created by George Birch on 10/9/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

@_spi(STP) @testable import StripeCore
@_spi(STP) @_spi(CryptoOnrampAlpha) @testable import StripePaymentSheet
import UIKit
import XCTest

#if !os(visionOS)
@MainActor
final class SheetDismissalAnalyticsTests: XCTestCase {

    func testKYCDismissalDoesNotLogPaymentSheetAnalytics() {
        defer { STPAnalyticsClient.sharedClient._testLogHistory = [] }
        for usesNativeSheet in [false, true] {
            // Given KYC content that opts out of PaymentSheet dismissal analytics
            let content = VerifyKYCContentViewController(info: StubKYCInfo(), appearance: .init())
            var cancellationCount = 0
            content.onResult = { result in
                guard case .canceled = result else {
                    XCTFail("Expected KYC cancellation")
                    return
                }
                cancellationCount += 1
            }
            let sheet = makeSheet(content: content, usesNativeSheet: usesNativeSheet)
            STPAnalyticsClient.sharedClient._testLogHistory = []

            // When dismissal is requested through the container
            sheet.didTapOrSwipeToDismiss()

            // Then cancellation is forwarded without adding any analytics
            XCTAssertEqual(cancellationCount, 1)
            XCTAssertTrue(STPAnalyticsClient.sharedClient._testLogHistory.isEmpty)

            // ...and the close button follows the same policy
            content.navigationBar.closeButtonRight.sendActions(for: .touchUpInside)
            XCTAssertEqual(cancellationCount, 2)
            XCTAssertTrue(STPAnalyticsClient.sharedClient._testLogHistory.isEmpty)
        }
    }

    func testHTMLConfirmationDismissalDoesNotLogPaymentSheetAnalytics() {
        defer { STPAnalyticsClient.sharedClient._testLogHistory = [] }
        for usesNativeSheet in [false, true] {
            // Given HTML confirmation content with the same analytics opt-out as KYC
            let content = HTMLConfirmationContentViewController(
                heading: "Confirm",
                html: "<p>Confirm your information.</p>",
                confirmationButtonTitle: "Confirm",
                appearance: .init(),
                brand: .link
            )
            var cancellationCount = 0
            content.onResult = { result in
                guard case .canceled = result else {
                    XCTFail("Expected HTML confirmation cancellation")
                    return
                }
                cancellationCount += 1
            }
            let sheet = makeSheet(content: content, usesNativeSheet: usesNativeSheet)
            STPAnalyticsClient.sharedClient._testLogHistory = []

            // When dismissal is requested through the container
            sheet.didTapOrSwipeToDismiss()

            // Then cancellation is forwarded without adding any analytics
            XCTAssertEqual(cancellationCount, 1)
            XCTAssertTrue(STPAnalyticsClient.sharedClient._testLogHistory.isEmpty)

            // ...and the close button follows the same policy
            content.navigationBar.closeButtonRight.sendActions(for: .touchUpInside)
            XCTAssertEqual(cancellationCount, 2)
            XCTAssertTrue(STPAnalyticsClient.sharedClient._testLogHistory.isEmpty)
        }
    }

    func testContainerAndCloseButtonUseTheSameAnalyticsPolicy() {
        defer { STPAnalyticsClient.sharedClient._testLogHistory = [] }
        for usesNativeSheet in [false, true] {
            for shouldLogDismissal in [false, true] {
                // Given content that controls whether dismissal logs PaymentSheet analytics
                let content = DismissalContentViewController(shouldLogDismissal: shouldLogDismissal)
                let sheet = makeSheet(content: content, usesNativeSheet: usesNativeSheet)
                STPAnalyticsClient.sharedClient._testLogHistory = []

                // When dismissal is requested through the container
                sheet.didTapOrSwipeToDismiss()

                // Then the content is notified and its analytics policy is honored
                XCTAssertEqual(content.dismissalCount, 1)
                XCTAssertEqual(
                    STPAnalyticsClient.sharedClient._testLogHistory.compactMap { $0["event"] as? String },
                    shouldLogDismissal ? ["mc_dismiss"] : []
                )

                // ...and the close button follows the same policy without duplicate events
                STPAnalyticsClient.sharedClient._testLogHistory = []
                content.navigationBar.closeButtonRight.sendActions(for: .touchUpInside)
                XCTAssertEqual(content.dismissalCount, 2)
                XCTAssertEqual(
                    STPAnalyticsClient.sharedClient._testLogHistory.compactMap { $0["event"] as? String },
                    shouldLogDismissal ? ["mc_dismiss"] : []
                )
            }
        }
    }

    func testDismissalUsesOriginalContentsAnalyticsPolicy() {
        defer { STPAnalyticsClient.sharedClient._testLogHistory = [] }
        for usesNativeSheet in [false, true] {
            for shouldLogDismissal in [false, true] {
                // Given cancellation that replaces the screen with a different analytics policy
                let content = DismissalContentViewController(shouldLogDismissal: shouldLogDismissal)
                let replacement = DismissalContentViewController(shouldLogDismissal: !shouldLogDismissal)
                let sheet = makeSheet(content: content, usesNativeSheet: usesNativeSheet)
                content.onDismiss = { [weak sheet] in
                    sheet?.setViewControllers([replacement])
                }
                STPAnalyticsClient.sharedClient._testLogHistory = []

                // When the dismissal callback changes the displayed content
                sheet.didTapOrSwipeToDismiss()

                // Then logging uses the dismissed screen's policy
                XCTAssertEqual(content.dismissalCount, 1)
                XCTAssertEqual(replacement.dismissalCount, 0)
                XCTAssertEqual(
                    STPAnalyticsClient.sharedClient._testLogHistory.compactMap { $0["event"] as? String },
                    shouldLogDismissal ? ["mc_dismiss"] : []
                )
            }
        }
    }

    func testKYCCoordinatorDismissalDoesNotLogPaymentSheetAnalytics() {
        defer { STPAnalyticsClient.sharedClient._testLogHistory = [] }
        // Given the real KYC coordinator and its factory-created container
        let controller = VerifyKYCViewController(info: StubKYCInfo(), appearance: .init())
        var cancellationCount = 0
        controller.onResult = { result in
            guard case .canceled = result else {
                XCTFail("Expected KYC cancellation")
                return
            }
            cancellationCount += 1
        }
        STPAnalyticsClient.sharedClient._testLogHistory = []

        // When dismissal is requested through the coordinator's container
        controller.sheetContainer.didTapOrSwipeToDismiss()

        // Then cancellation is forwarded without adding any analytics
        XCTAssertEqual(cancellationCount, 1)
        XCTAssertTrue(STPAnalyticsClient.sharedClient._testLogHistory.isEmpty)
    }

    func testHTMLConfirmationCoordinatorDismissalDoesNotLogPaymentSheetAnalytics() {
        defer { STPAnalyticsClient.sharedClient._testLogHistory = [] }
        // Given the real HTML confirmation coordinator and its factory-created container
        let controller = HTMLConfirmationViewController(
            heading: "Confirm",
            html: "<p>Confirm your information.</p>",
            confirmationButtonTitle: "Confirm",
            appearance: .init(),
            brand: .link
        )
        var cancellationCount = 0
        controller.onResult = { result in
            guard case .canceled = result else {
                XCTFail("Expected HTML confirmation cancellation")
                return
            }
            cancellationCount += 1
        }
        STPAnalyticsClient.sharedClient._testLogHistory = []

        // When dismissal is requested through the coordinator's container
        controller.sheetContainer.didTapOrSwipeToDismiss()

        // Then cancellation is forwarded without adding any analytics
        XCTAssertEqual(cancellationCount, 1)
        XCTAssertTrue(STPAnalyticsClient.sharedClient._testLogHistory.isEmpty)
    }

    private func makeSheet(content: BottomSheetContentViewController, usesNativeSheet: Bool) -> any PaymentSheetContainer {
        // Construct both implementations directly so Duo's required rollout cannot hide legacy coverage.
        if usesNativeSheet {
            return NativeSheetContainerViewController(
                contentViewController: content,
                appearance: .default,
                didCancelNative3DS2: {}
            )
        }
        return BottomSheetViewController(
            contentViewController: content,
            appearance: .default,
            didCancelNative3DS2: {}
        )
    }
}

private final class DismissalContentViewController: UIViewController, BottomSheetContentViewController, SheetNavigationBarDelegate {

    let navigationBar: SheetNavigationBar
    let requiresFullScreen = false
    private(set) var dismissalCount = 0
    var onDismiss: (() -> Void)?

    init(shouldLogDismissal: Bool = true) {
        navigationBar = SheetNavigationBar(appearance: .default, shouldLogPaymentSheetAnalyticsOnDismissal: shouldLogDismissal)
        super.init(nibName: nil, bundle: nil)
        navigationBar.delegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func didTapOrSwipeToDismiss() {
        dismissalCount += 1
        onDismiss?()
    }

    func sheetNavigationBarDidClose(_ sheetNavigationBar: SheetNavigationBar) {
        didTapOrSwipeToDismiss()
    }

    func sheetNavigationBarDidBack(_ sheetNavigationBar: SheetNavigationBar) {}
}

private struct StubKYCInfo: VerifyKYCInfo {

    let firstName = "Jane"
    let lastName: String? = "Doe"
    let dateOfBirthDay = 1
    let dateOfBirthMonth = 1
    let dateOfBirthYear = 1990
    let city: String? = "San Francisco"
    let country: String? = "US"
    let line1: String? = "123 Main Street"
    let line2: String? = nil
    let postalCode: String? = "94107"
    let state: String? = "CA"
    let idNumberLast4: String? = "1234"
}
#endif
