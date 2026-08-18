//
//  ExpressCheckoutElementViewTests.swift
//  StripePaymentSheetTests
//
//  Created by Joyce Qin on 7/22/26.
//

import PassKit
@testable @_spi(STP) import StripeCore
@testable @_spi(STP) import StripePaymentSheet
import UIKit
import XCTest

@MainActor
final class ExpressCheckoutElementViewTests: XCTestCase {

    // MARK: - resolveButtons tests

    func testNoButtonsWhenSessionHasNoWalletTypes() {
        // Given a session with no wallet types in the elements session
        let session = CheckoutTestHelpers.makeOpenSession().makePublicSession()
        let configuration = Checkout.Configuration(clientSecret: "cs_test_123_secret_abc", returnURL: "stripe-ios-test://checkout-return")

        XCTAssertEqual(
            ExpressCheckoutElementUtilities.resolveButtons(for: session, configuration: configuration),
            []
        )
    }

    func testNoApplePayButtonWithoutApplePayConfiguration() {
        // Given a session that includes apple_pay, but no applePayConfiguration
        let session = makeSessionWithWalletTypes(["apple_pay"]).makePublicSession()
        let configuration = Checkout.Configuration(clientSecret: "cs_test_123_secret_abc", returnURL: "stripe-ios-test://checkout-return")

        let buttons = ExpressCheckoutElementUtilities.resolveButtons(for: session, configuration: configuration)
        XCTAssertFalse(buttons.contains(.applePay))
    }

    func testApplePayButtonWithApplePayConfiguration() {
        // Given a session with apple_pay and an applePayConfiguration
        let session = makeSessionWithWalletTypes(["apple_pay"]).makePublicSession()
        var configuration = Checkout.Configuration(clientSecret: "cs_test_123_secret_abc", returnURL: "stripe-ios-test://checkout-return")
        configuration.applePayConfiguration = Checkout.ApplePayConfiguration(merchantId: "merchant.com.example")

        let buttons = ExpressCheckoutElementUtilities.resolveButtons(for: session, configuration: configuration)
        XCTAssertEqual(buttons.contains(.applePay), StripeAPI.deviceSupportsApplePay())
    }

    func testLinkButtonShownByDefault() {
        // Given a session with link and no linkConfiguration override
        let session = makeSessionWithWalletTypes(["link"]).makePublicSession()
        let configuration = Checkout.Configuration(clientSecret: "cs_test_123_secret_abc", returnURL: "stripe-ios-test://checkout-return")

        let buttons = ExpressCheckoutElementUtilities.resolveButtons(for: session, configuration: configuration)
        XCTAssertTrue(buttons.contains(.link))
    }

    // MARK: - Link button presenting view controller

    func testLinkButtonTap_passesTopmostViewControllerFromOwnWindow() async {
        // Given a Link button embedded under a specific window/root view controller
        let (uiView, delegate) = makeUIView(walletTypes: ["link"])
        let rootViewController = UIViewController()
        let window = makeWindow(rootViewController: rootViewController, containing: uiView)
        defer { window.isHidden = true }

        // When the Link button is tapped
        let expectation = expectation(description: "delegate called")
        delegate.didConfirm = { _, _ in expectation.fulfill() }
        uiView.perform(NSSelectorFromString("handleLinkTapped"))

        // Then the delegate is called with this button's own root view controller, not some other VC
        await fulfillment(of: [expectation], timeout: 2)
        XCTAssertEqual(delegate.receivedPaymentMethod, .link)
        XCTAssertTrue(delegate.receivedPresentingViewController === rootViewController)
    }

    func testLinkButtonTap_resolvesTopmostPresentedViewControllerInOwnWindow() async {
        // Given a Link button whose window has a presented (modal) view controller on top of the root
        let (uiView, delegate) = makeUIView(walletTypes: ["link"])
        let rootViewController = UIViewController()
        let window = makeWindow(rootViewController: rootViewController, containing: uiView)
        defer { window.isHidden = true }
        let presentedViewController = UIViewController()
        rootViewController.present(presentedViewController, animated: false)

        // When the Link button is tapped
        let expectation = expectation(description: "delegate called")
        delegate.didConfirm = { _, _ in expectation.fulfill() }
        uiView.perform(NSSelectorFromString("handleLinkTapped"))

        // Then the delegate is called with the topmost presented view controller in this button's own
        // window, e.g. in case some other window/scene's "visible" view controller differs from this one.
        await fulfillment(of: [expectation], timeout: 2)
        XCTAssertTrue(delegate.receivedPresentingViewController === presentedViewController)
    }

    func testLinkButtonTap_noWindow_passesNilPresentingViewController() async {
        // Given a Link button that hasn't been added to any window
        let (uiView, delegate) = makeUIView(walletTypes: ["link"])

        // When the Link button is tapped
        let expectation = expectation(description: "delegate called")
        delegate.didConfirm = { _, _ in expectation.fulfill() }
        uiView.perform(NSSelectorFromString("handleLinkTapped"))

        // Then the delegate is called with a nil presenting view controller, letting the caller decide
        // on a fallback, rather than reaching for some other window's view controller.
        await fulfillment(of: [expectation], timeout: 2)
        XCTAssertNil(delegate.receivedPresentingViewController)
    }

    func testApplePayButtonTap_alsoPassesOwnWindowsViewController() async {
        // Given an Apple Pay button embedded under a specific window/root view controller
        let (uiView, delegate) = makeUIView(walletTypes: ["apple_pay"])
        let rootViewController = UIViewController()
        let window = makeWindow(rootViewController: rootViewController, containing: uiView)
        defer { window.isHidden = true }

        // When the Apple Pay button is tapped
        let expectation = expectation(description: "delegate called")
        delegate.didConfirm = { _, _ in expectation.fulfill() }
        uiView.perform(NSSelectorFromString("handleApplePayTapped"))

        // Then the delegate is called with this button's own root view controller, for parity with Link
        await fulfillment(of: [expectation], timeout: 2)
        XCTAssertEqual(delegate.receivedPaymentMethod, .applePay)
        XCTAssertTrue(delegate.receivedPresentingViewController === rootViewController)
    }

    // MARK: - Helpers

    private func makeSessionWithWalletTypes(_ walletTypes: [String]) -> PaymentPagesAPIResponse {
        let elementsSession: [String: Any] = [
            "session_id": "es_test",
            "payment_method_preference": ["ordered_payment_method_types": ["card"]],
            "ordered_payment_method_types_and_wallets": walletTypes,
        ]
        return CheckoutTestHelpers.makeSession(["elements_session": elementsSession])
    }

    private func makeUIView(walletTypes: [String]) -> (ExpressCheckoutElementUIView, MockExpressCheckoutElementDelegate) {
        let session = makeSessionWithWalletTypes(walletTypes).makePublicSession()
        var configuration = Checkout.Configuration(clientSecret: "cs_test_123_secret_abc", returnURL: "stripe-ios-test://checkout-return")
        configuration.applePayConfiguration = Checkout.ApplePayConfiguration(merchantId: "merchant.com.example")
        let delegate = MockExpressCheckoutElementDelegate()
        let uiView = ExpressCheckoutElementUIView(session: session, configuration: configuration, delegate: delegate)
        return (uiView, delegate)
    }

    private func makeWindow(rootViewController: UIViewController, containing uiView: ExpressCheckoutElementUIView) -> UIWindow {
        rootViewController.view.addSubview(uiView)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        window.rootViewController = rootViewController
        window.makeKeyAndVisible()
        return window
    }
}

// MARK: - MockExpressCheckoutElementDelegate

@MainActor
private final class MockExpressCheckoutElementDelegate: ExpressCheckoutElementDelegate {
    var confirmResult: Checkout.ConfirmResult = .canceled
    var receivedPaymentMethod: ExpressCheckoutElement.PaymentMethod?
    var receivedPresentingViewController: UIViewController?
    var didConfirm: ((ExpressCheckoutElement.PaymentMethod, UIViewController?) -> Void)?

    func expressCheckoutElementShouldConfirm(
        _ paymentMethod: ExpressCheckoutElement.PaymentMethod,
        presentingViewController: UIViewController?
    ) async -> Checkout.ConfirmResult {
        receivedPaymentMethod = paymentMethod
        receivedPresentingViewController = presentingViewController
        didConfirm?(paymentMethod, presentingViewController)
        return confirmResult
    }
}
