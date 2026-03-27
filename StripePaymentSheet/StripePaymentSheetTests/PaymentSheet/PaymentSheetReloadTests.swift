//
//  PaymentSheetReloadTests.swift
//  StripePaymentSheetTests
//
//  Created by Nick Porter on 3/25/26.
//

@_spi(STP) import StripeCore
import StripeCoreTestUtils
@_spi(STP) @testable import StripePaymentSheet
@_spi(STP) import StripeUICore
import XCTest

@MainActor
final class PaymentSheetReloadTests: XCTestCase {

    override func setUpWithError() throws {
        let expectation = expectation(description: "Load specs")
        AddressSpecProvider.shared.loadAddressSpecs {
            FormSpecProvider.shared.load { _ in
                expectation.fulfill()
            }
        }
        waitForExpectations(timeout: 1)
    }

    func makeLoadResult(savedPaymentMethods: [STPPaymentMethod] = []) -> PaymentSheetLoader.LoadResult {
        return .init(
            intent: ._testPaymentIntent(paymentMethodTypes: [.card]),
            elementsSession: ._testCardValue(),
            savedPaymentMethods: savedPaymentMethods,
            paymentMethodTypes: [.stripe(.card)]
        )
    }

    // MARK: - setReloading tests

    func testSetReloading_vertical() {
        let loadResult = makeLoadResult()
        let vc = PaymentSheetVerticalViewController(
            configuration: ._testValue_MostPermissive(isApplePayEnabled: false),
            loadResult: loadResult,
            isFlowController: false,
            analyticsHelper: ._testValue()
        )
        _ = vc.view

        vc.setReloading(true)
        XCTAssertFalse(vc.view.isUserInteractionEnabled)
        XCTAssertFalse(vc.navigationBar.isUserInteractionEnabled)
        XCTAssertTrue(vc.allowsDragToDismiss, "Should prevent drag-to-dismiss while reloading")

        vc.setReloading(false)
        XCTAssertTrue(vc.view.isUserInteractionEnabled)
        XCTAssertTrue(vc.navigationBar.isUserInteractionEnabled)
        XCTAssertFalse(vc.allowsDragToDismiss)
    }

    func testSetReloading_horizontal() {
        let loadResult = makeLoadResult()
        let delegate = MockPaymentSheetViewControllerDelegate()
        let vc = PaymentSheetViewController(
            configuration: ._testValue_MostPermissive(isApplePayEnabled: false),
            loadResult: loadResult,
            analyticsHelper: ._testValue(),
            delegate: delegate,
            previousPaymentOption: nil
        )
        _ = vc.view

        vc.setReloading(true)
        XCTAssertFalse(vc.view.isUserInteractionEnabled)
        XCTAssertFalse(vc.navigationBar.isUserInteractionEnabled)
        XCTAssertFalse(vc.isDismissable)

        vc.setReloading(false)
        XCTAssertTrue(vc.view.isUserInteractionEnabled)
        XCTAssertTrue(vc.navigationBar.isUserInteractionEnabled)
        XCTAssertTrue(vc.isDismissable)
    }

    // MARK: - setReloadError tests

    func testSetReloadError_vertical() {
        let loadResult = makeLoadResult()
        let vc = PaymentSheetVerticalViewController(
            configuration: ._testValue_MostPermissive(isApplePayEnabled: false),
            loadResult: loadResult,
            isFlowController: false,
            analyticsHelper: ._testValue()
        )
        _ = vc.view

        let testError = NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        vc.setReloadError(testError)
        XCTAssertNotNil(vc.error)
        XCTAssertEqual((vc.error as? NSError)?.domain, "test")
    }

    func testSetReloadError_horizontal() {
        let loadResult = makeLoadResult()
        let delegate = MockPaymentSheetViewControllerDelegate()
        let vc = PaymentSheetViewController(
            configuration: ._testValue_MostPermissive(isApplePayEnabled: false),
            loadResult: loadResult,
            analyticsHelper: ._testValue(),
            delegate: delegate,
            previousPaymentOption: nil
        )
        _ = vc.view

        let testError = NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        vc.setReloadError(testError)
        XCTAssertNotNil(vc.error)
        XCTAssertEqual((vc.error as? NSError)?.domain, "test")
    }
}

// MARK: - Mock delegate

private class MockPaymentSheetViewControllerDelegate: PaymentSheetViewControllerDelegate {
    func paymentSheetViewControllerShouldConfirm(
        _ paymentSheetViewController: PaymentSheetViewControllerProtocol,
        with paymentOption: PaymentOption,
        completion: @escaping (PaymentSheetResult, STPAnalyticsClient.DeferredIntentConfirmationType?) -> Void
    ) {
        completion(.canceled, nil)
    }

    func paymentSheetViewControllerDidFinish(
        _ paymentSheetViewController: PaymentSheetViewControllerProtocol,
        result: PaymentSheetResult
    ) {}

    func paymentSheetViewControllerDidCancel(
        _ paymentSheetViewController: PaymentSheetViewControllerProtocol
    ) {}

    func paymentSheetViewControllerDidSelectPayWithLink(
        _ paymentSheetViewController: PaymentSheetViewControllerProtocol
    ) {}

}
