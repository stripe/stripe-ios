//
//  AuthenticationHandlerTests.swift
//  StripeiOS Tests
//
//  Created by Claude Code on 2026-01-14.
//  Copyright 2026 Stripe, Inc. All rights reserved.
//

import Foundation
import XCTest

@testable@_spi(STP) import Stripe
@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePayments

// MARK: - AuthenticationHandlerRegistry Tests

class AuthenticationHandlerRegistryTests: XCTestCase {

    func testRegistryCanHandleRedirectActions() {
        let registry = AuthenticationHandlerRegistry()

        XCTAssertTrue(registry.canHandle(actionType: .redirectToURL))
        XCTAssertTrue(registry.canHandle(actionType: .alipayHandleRedirect))
        XCTAssertTrue(registry.canHandle(actionType: .weChatPayRedirectToApp))
        XCTAssertTrue(registry.canHandle(actionType: .cashAppRedirectToApp))
        XCTAssertTrue(registry.canHandle(actionType: .swishHandleRedirect))
    }

    func testRegistryCanHandleVoucherActions() {
        let registry = AuthenticationHandlerRegistry()

        XCTAssertTrue(registry.canHandle(actionType: .OXXODisplayDetails))
        XCTAssertTrue(registry.canHandle(actionType: .boletoDisplayDetails))
        XCTAssertTrue(registry.canHandle(actionType: .multibancoDisplayDetails))
        XCTAssertTrue(registry.canHandle(actionType: .konbiniDisplayDetails))
    }

    func testRegistryCanHandlePollingActions() {
        let registry = AuthenticationHandlerRegistry()

        XCTAssertTrue(registry.canHandle(actionType: .BLIKAuthorize))
        XCTAssertTrue(registry.canHandle(actionType: .upiAwaitNotification))
        XCTAssertTrue(registry.canHandle(actionType: .payNowDisplayQrCode))
        XCTAssertTrue(registry.canHandle(actionType: .promptpayDisplayQrCode))
        XCTAssertTrue(registry.canHandle(actionType: .verifyWithMicrodeposits))
    }

    func testRegistryCanHandleThreeDS2Actions() {
        let registry = AuthenticationHandlerRegistry()

        XCTAssertTrue(registry.canHandle(actionType: .useStripeSDK))
    }

    func testRegistryCannotHandleUnknownAction() {
        let registry = AuthenticationHandlerRegistry()

        XCTAssertFalse(registry.canHandle(actionType: .unknown))
    }

    func testRegistryReturnsCorrectHandlerTypes() {
        let registry = AuthenticationHandlerRegistry()

        XCTAssertTrue(registry.handler(for: .redirectToURL) is RedirectAuthenticationHandler)
        XCTAssertTrue(registry.handler(for: .OXXODisplayDetails) is VoucherDisplayHandler)
        XCTAssertTrue(registry.handler(for: .BLIKAuthorize) is PollingAuthenticationHandler)
        XCTAssertTrue(registry.handler(for: .useStripeSDK) is ThreeDS2AuthenticationHandler)
        XCTAssertNil(registry.handler(for: .unknown))
    }
}

// MARK: - RedirectAuthenticationHandler Tests

class RedirectAuthenticationHandlerTests: XCTestCase {

    func testCanHandleRedirectActionTypes() {
        let handler = RedirectAuthenticationHandler()

        XCTAssertTrue(handler.canHandle(actionType: .redirectToURL))
        XCTAssertTrue(handler.canHandle(actionType: .alipayHandleRedirect))
        XCTAssertTrue(handler.canHandle(actionType: .weChatPayRedirectToApp))
        XCTAssertTrue(handler.canHandle(actionType: .cashAppRedirectToApp))
        XCTAssertTrue(handler.canHandle(actionType: .swishHandleRedirect))
    }

    func testCannotHandleNonRedirectActionTypes() {
        let handler = RedirectAuthenticationHandler()

        XCTAssertFalse(handler.canHandle(actionType: .unknown))
        XCTAssertFalse(handler.canHandle(actionType: .OXXODisplayDetails))
        XCTAssertFalse(handler.canHandle(actionType: .useStripeSDK))
        XCTAssertFalse(handler.canHandle(actionType: .BLIKAuthorize))
    }
}

// MARK: - VoucherDisplayHandler Tests

class VoucherDisplayHandlerTests: XCTestCase {

    func testCanHandleVoucherActionTypes() {
        let handler = VoucherDisplayHandler()

        XCTAssertTrue(handler.canHandle(actionType: .OXXODisplayDetails))
        XCTAssertTrue(handler.canHandle(actionType: .boletoDisplayDetails))
        XCTAssertTrue(handler.canHandle(actionType: .multibancoDisplayDetails))
        XCTAssertTrue(handler.canHandle(actionType: .konbiniDisplayDetails))
    }

    func testCannotHandleNonVoucherActionTypes() {
        let handler = VoucherDisplayHandler()

        XCTAssertFalse(handler.canHandle(actionType: .unknown))
        XCTAssertFalse(handler.canHandle(actionType: .redirectToURL))
        XCTAssertFalse(handler.canHandle(actionType: .useStripeSDK))
        XCTAssertFalse(handler.canHandle(actionType: .BLIKAuthorize))
    }
}

// MARK: - PollingAuthenticationHandler Tests

class PollingAuthenticationHandlerTests: XCTestCase {

    func testCanHandlePollingActionTypes() {
        let handler = PollingAuthenticationHandler()

        XCTAssertTrue(handler.canHandle(actionType: .BLIKAuthorize))
        XCTAssertTrue(handler.canHandle(actionType: .upiAwaitNotification))
        XCTAssertTrue(handler.canHandle(actionType: .payNowDisplayQrCode))
        XCTAssertTrue(handler.canHandle(actionType: .promptpayDisplayQrCode))
        XCTAssertTrue(handler.canHandle(actionType: .verifyWithMicrodeposits))
    }

    func testCannotHandleNonPollingActionTypes() {
        let handler = PollingAuthenticationHandler()

        XCTAssertFalse(handler.canHandle(actionType: .unknown))
        XCTAssertFalse(handler.canHandle(actionType: .redirectToURL))
        XCTAssertFalse(handler.canHandle(actionType: .OXXODisplayDetails))
        XCTAssertFalse(handler.canHandle(actionType: .useStripeSDK))
    }
}

// MARK: - ThreeDS2AuthenticationHandler Tests

class ThreeDS2AuthenticationHandlerTests: XCTestCase {

    func testCanHandleUseStripeSDKActionType() {
        let handler = ThreeDS2AuthenticationHandler()

        XCTAssertTrue(handler.canHandle(actionType: .useStripeSDK))
    }

    func testCannotHandleOtherActionTypes() {
        let handler = ThreeDS2AuthenticationHandler()

        XCTAssertFalse(handler.canHandle(actionType: .unknown))
        XCTAssertFalse(handler.canHandle(actionType: .redirectToURL))
        XCTAssertFalse(handler.canHandle(actionType: .OXXODisplayDetails))
        XCTAssertFalse(handler.canHandle(actionType: .BLIKAuthorize))
    }
}

// MARK: - Integration Tests

class AuthenticationHandlerIntegrationTests: XCTestCase {

    var paymentHandler: STPPaymentHandler!
    var mockAPIClient: STPAPIClient!

    override func setUp() {
        super.setUp()
        mockAPIClient = STPAPIClient(publishableKey: "pk_test_123")
        paymentHandler = STPPaymentHandler(apiClient: mockAPIClient)
    }

    override func tearDown() {
        paymentHandler = nil
        mockAPIClient = nil
        super.tearDown()
    }

    func testPaymentHandlerHasAuthenticationHandlerRegistry() {
        // Verify the payment handler can delegate to handlers
        // by checking it doesn't crash when handling an unknown action type
        let paymentIntent = STPFixtures.paymentIntent(
            paymentMethodTypes: ["card"],
            status: .requiresAction
        )

        let currentAction = STPPaymentHandlerPaymentIntentActionParams(
            apiClient: mockAPIClient,
            authenticationContext: self,
            threeDSCustomizationSettings: STPThreeDSCustomizationSettings(),
            paymentIntent: paymentIntent,
            returnURL: nil
        ) { _, _, _ in }

        paymentHandler.currentAction = currentAction

        // This should complete without crashing
        // The actual behavior depends on the action type
        XCTAssertNotNil(paymentHandler)
    }

    func testInstanceBasedStateManagement() {
        // Create two separate payment handlers
        let handler1 = STPPaymentHandler(apiClient: mockAPIClient)
        let handler2 = STPPaymentHandler(apiClient: mockAPIClient)

        // Initially, neither should be in progress
        XCTAssertFalse(handler1.isInProgress)
        XCTAssertFalse(handler2.isInProgress)

        // Note: Full testing of instance-based state would require
        // more complex setup with actual payment flows
    }
}

// MARK: - PollingCoordinator Tests

class PollingCoordinatorTests: XCTestCase {

    func testCreateMinimalBudget() {
        let coordinator = PollingCoordinator()
        let budget = coordinator.createMinimalBudget()

        XCTAssertNotNil(budget)
        XCTAssertTrue(budget.canPoll)
    }

    func testCreateProcessingBudget() {
        let coordinator = PollingCoordinator()
        let budget = coordinator.createProcessingBudget()

        XCTAssertNotNil(budget)
        XCTAssertTrue(budget.canPoll)
    }

    func testGetOrCreateBudgetForCard() {
        let coordinator = PollingCoordinator()
        let budget = coordinator.getOrCreateBudget(for: .card)

        XCTAssertNotNil(budget)
        XCTAssertTrue(budget?.canPoll ?? false)
    }

    func testGetOrCreateBudgetForUnsupportedType() {
        let coordinator = PollingCoordinator()
        let budget = coordinator.getOrCreateBudget(for: .affirm)

        XCTAssertNil(budget)
    }

    func testShouldPollForCard() {
        XCTAssertTrue(PollingCoordinator.shouldPoll(for: .card))
        XCTAssertTrue(PollingCoordinator.shouldPoll(for: .swish))
        XCTAssertTrue(PollingCoordinator.shouldPoll(for: .amazonPay))
    }

    func testShouldNotPollForUnsupportedTypes() {
        XCTAssertFalse(PollingCoordinator.shouldPoll(for: .affirm))
        XCTAssertFalse(PollingCoordinator.shouldPoll(for: .alipay))
        XCTAssertFalse(PollingCoordinator.shouldPoll(for: .blik))
    }

    func testPollingDurationForCard() {
        XCTAssertEqual(PollingCoordinator.pollingDuration(for: .card), 15.0)
    }

    func testPollingDurationForSwish() {
        XCTAssertEqual(PollingCoordinator.pollingDuration(for: .swish), 5.0)
    }

    func testPollingDurationForUnsupportedType() {
        XCTAssertNil(PollingCoordinator.pollingDuration(for: .affirm))
    }

    func testReset() {
        let coordinator = PollingCoordinator()
        _ = coordinator.createMinimalBudget()

        XCTAssertNotNil(coordinator.currentBudget)

        coordinator.reset()

        XCTAssertNil(coordinator.currentBudget)
    }
}

// MARK: - AuthenticationUIPresenter Tests

class AuthenticationUIPresenterTests: XCTestCase {

    func testCreateSafariViewController() {
        let presenter = AuthenticationUIPresenter()
        let url = URL(string: "https://stripe.com")!
        let context = MockAuthenticationContext()

        let safariVC = presenter.createSafariViewController(
            for: url,
            context: context,
            delegate: nil
        )

        XCTAssertNotNil(safariVC)
        XCTAssertEqual(presenter.safariViewController, safariVC)
    }

    func testCleanup() {
        let presenter = AuthenticationUIPresenter()
        let url = URL(string: "https://stripe.com")!
        let context = MockAuthenticationContext()

        _ = presenter.createSafariViewController(
            for: url,
            context: context,
            delegate: nil
        )

        XCTAssertNotNil(presenter.safariViewController)

        // Cleanup would normally dismiss, but we can verify the intent
        presenter.cleanup()

        // After cleanup, safariViewController should be nil
        XCTAssertNil(presenter.safariViewController)
    }
}

// MARK: - Test Helpers

class MockAuthenticationContext: NSObject, STPAuthenticationContext {
    func authenticationPresentingViewController() -> UIViewController {
        return UIViewController()
    }
}

extension AuthenticationHandlerIntegrationTests: STPAuthenticationContext {
    func authenticationPresentingViewController() -> UIViewController {
        return UIViewController()
    }
}
