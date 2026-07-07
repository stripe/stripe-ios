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

    func testSetReloading_true() {
        let formVC = makeFormViewController()
        XCTAssertTrue(formVC.isUserInteractionEnabled)

        formVC.setReloading(true)

        XCTAssertTrue(formVC.isReloading)
        XCTAssertFalse(formVC.isUserInteractionEnabled)
        XCTAssertFalse(formVC.view.isUserInteractionEnabled)
        XCTAssertEqual(formVC.primaryButton.status, .processing)
    }

    func testSetReloading_false() {
        let formVC = makeFormViewController()

        formVC.setReloading(true)
        XCTAssertFalse(formVC.isUserInteractionEnabled)

        formVC.setReloading(false)

        XCTAssertFalse(formVC.isReloading)
        XCTAssertTrue(formVC.isUserInteractionEnabled)
        XCTAssertTrue(formVC.view.isUserInteractionEnabled)
        XCTAssertEqual(formVC.primaryButton.status, .disabled)
    }

}

// MARK: - EmbeddedPaymentElement checkoutDidUpdate routing

@MainActor
final class EmbeddedPaymentElementCheckoutRoutingTests: XCTestCase {

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
