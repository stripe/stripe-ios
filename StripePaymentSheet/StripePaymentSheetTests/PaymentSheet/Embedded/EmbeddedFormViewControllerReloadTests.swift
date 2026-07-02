//
//  EmbeddedFormViewControllerReloadTests.swift
//  StripePaymentSheetTests
//
//  Created by Nick Porter on 7/2/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

@_spi(STP) import StripeCore
@_spi(STP) import StripeCoreTestUtils
@_spi(STP) import StripePayments
@_spi(STP) @testable import StripePaymentSheet
@_spi(STP) import StripeUICore
import XCTest

@MainActor
final class EmbeddedFormViewControllerReloadTests: XCTestCase {

    struct MockError: LocalizedError {
        var errorDescription: String? { "Mock reload error" }
    }

    /// Retained for the lifetime of each test since `EmbeddedFormViewController.delegate` is weak.
    private let mockDelegate = MockDelegate()

    override func setUp() async throws {
        await PaymentSheetLoader.loadMiscellaneousSingletons()
    }

    // MARK: - Helpers

    private func makeFormViewController(
        paymentMethodType: STPPaymentMethodType = .card
    ) -> EmbeddedFormViewController {
        var configuration = EmbeddedPaymentElement.Configuration()
        configuration.formSheetAction = .confirm(completion: { _ in })
        let formVC = EmbeddedFormViewController(
            configuration: configuration,
            intent: ._testPaymentIntent(paymentMethodTypes: [paymentMethodType]),
            elementsSession: ._testValue(paymentMethodTypes: [paymentMethodType.identifier]),
            shouldUseNewCardNewCardHeader: false,
            paymentMethodType: .stripe(paymentMethodType),
            analyticsHelper: ._testValue(),
            delegate: mockDelegate
        )
        _ = formVC.view
        return formVC
    }

    // MARK: - setReloading

    func testSetReloadingTrueDisablesInteractionAndShowsSpinner() {
        let formVC = makeFormViewController()
        XCTAssertTrue(formVC.isUserInteractionEnabled)

        formVC.setReloading(true)

        XCTAssertTrue(formVC._test_isReloading)
        XCTAssertFalse(formVC.isUserInteractionEnabled)
        XCTAssertFalse(formVC.view.isUserInteractionEnabled)
        // Reloading shows the processing spinner on the primary button.
        XCTAssertEqual(formVC._test_primaryButtonStatus, .processing)
        // Dismiss is still allowed during reload (only blocked while a payment is in flight).
        XCTAssertFalse(formVC.allowsDragToDismiss)
    }

    func testSetReloadingFalseReenablesInteraction() {
        let formVC = makeFormViewController()

        formVC.setReloading(true)
        XCTAssertFalse(formVC.isUserInteractionEnabled)

        formVC.setReloading(false)

        XCTAssertFalse(formVC._test_isReloading)
        XCTAssertTrue(formVC.isUserInteractionEnabled)
        XCTAssertTrue(formVC.view.isUserInteractionEnabled)
        // No card entered, so the button returns to the disabled (not processing) state.
        XCTAssertEqual(formVC._test_primaryButtonStatus, .disabled)
    }

    // MARK: - setReloadError

    func testSetReloadErrorSetsAndDisplaysError() {
        let formVC = makeFormViewController()

        XCTAssertNil(formVC._test_error)
        XCTAssertNil(formVC._test_errorLabelText)

        let error = MockError()
        formVC.setReloadError(error)

        XCTAssertNotNil(formVC._test_error)
        XCTAssertEqual((formVC._test_error as? MockError)?.errorDescription, error.errorDescription)
        XCTAssertEqual(formVC._test_errorLabelText, error.errorDescription)
    }
}

// MARK: - EmbeddedPaymentElement checkoutDidUpdate routing

@MainActor
final class EmbeddedPaymentElementCheckoutRoutingTests: XCTestCase {

    /// Retained for the lifetime of each test since `EmbeddedFormViewController.delegate` is weak.
    private let mockFormDelegate = MockDelegate()

    private func makeElement() -> EmbeddedPaymentElement {
        let configuration = EmbeddedPaymentElement.Configuration._testValue_MostPermissive(isApplePayEnabled: false)
        let loadResult = PaymentSheetLoader.LoadResult(
            intent: ._testPaymentIntent(paymentMethodTypes: [.card]),
            elementsSession: ._testValue(paymentMethodTypes: ["card"]),
            savedPaymentMethods: [],
            paymentMethodTypes: [.stripe(.card)],
            paymentMethodMessagingPromotionsHelper: ._testValue(),
            paymentMethodOrientation: .vertical
        )
        return EmbeddedPaymentElement(
            configuration: configuration,
            loadResult: loadResult,
            analyticsHelper: ._testValue()
        )
    }

    private func makeFormViewController() -> EmbeddedFormViewController {
        var configuration = EmbeddedPaymentElement.Configuration()
        configuration.formSheetAction = .confirm(completion: { _ in })
        return EmbeddedFormViewController(
            configuration: configuration,
            intent: ._testPaymentIntent(paymentMethodTypes: [.card]),
            elementsSession: ._testValue(paymentMethodTypes: ["card"]),
            shouldUseNewCardNewCardHeader: false,
            paymentMethodType: .stripe(.card),
            analyticsHelper: ._testValue(),
            delegate: mockFormDelegate
        )
    }

    /// `checkoutDidUpdate` routes to `performReload` (instead of `update`) only when a bottom sheet is
    /// presented. That branch is gated on `isSheetPresented`, so these verify the flag directly.
    func testIsSheetPresentedFalseWhenNoSheetPresented() {
        let sut = makeElement()
        sut.presentingViewController = UIViewController()

        XCTAssertFalse(sut.isSheetPresented)
    }

    func testIsSheetPresentedTrueWhenBottomSheetPresented() {
        let sut = makeElement()

        // Host the presenting VC in a real window so `present` takes effect.
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 375, height: 700))
        let presentingVC = UIViewController()
        window.rootViewController = presentingVC
        window.isHidden = false
        sut.presentingViewController = presentingVC

        let bottomSheet = BottomSheetViewController(
            contentViewController: makeFormViewController(),
            appearance: .default,
            isTestMode: false,
            didCancelNative3DS2: {}
        )
        presentingVC.present(bottomSheet, animated: false)

        XCTAssertTrue(sut.presentingViewController?.presentedViewController is BottomSheetViewController)
        XCTAssertTrue(sut.isSheetPresented)
    }
}

// MARK: - Mocks

@MainActor
private final class MockDelegate: EmbeddedFormViewControllerDelegate {
    func embeddedFormViewControllerShouldConfirm(
        _ embeddedFormViewController: EmbeddedFormViewController,
        with paymentOption: PaymentOption,
        completion: @escaping (PaymentSheetResult, STPAnalyticsClient.DeferredIntentConfirmationType?) -> Void
    ) {}

    func embeddedFormViewControllerDidCompleteConfirmation(
        _ embeddedFormViewController: EmbeddedFormViewController,
        result: PaymentSheetResult
    ) {}

    func embeddedFormViewControllerDidCancel(_ embeddedFormViewController: EmbeddedFormViewController) {}

    func embeddedFormViewControllerDidContinue(_ embeddedFormViewController: EmbeddedFormViewController) {}
}
