//
//  CheckoutApplePayContextFunctionalTest.swift
//  StripePaymentSheetTests
//
//  Created by Joyce Qin on 8/11/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

import OHHTTPStubs
import OHHTTPStubsSwift
import PassKit
@testable @_spi(STP) import StripeCore
@testable @_spi(STP) import StripeCoreTestUtils
@testable @_spi(STP) import StripePayments
@testable @_spi(STP) import StripePaymentSheet
import StripePaymentsObjcTestUtils
@testable @_spi(STP) import StripePaymentsTestUtils
import XCTest

@MainActor
class CheckoutApplePayContextFunctionalTest: STPNetworkStubbingTestCase {
    func testCompletesPayment() async throws {
        let (context, _) = try await makeContext()

        let didComplete = expectation(description: "Apple Pay completes")
        Task {
            let result = await context.presentApplePay()
            XCTAssertEqual(result.paymentSheetResult, .completed)
            didComplete.fulfill()
        }
        _startApplePayForContext(context, withExpectedStatus: .success)
        await fulfillment(of: [didComplete], timeout: STPTestingNetworkRequestTimeout)
    }

    func testCancelAfterConfirmStillSucceeds() async throws {
        // Given a cancel fires while the confirm is in-flight
        let (context, _) = try await makeContext()
        stub { urlRequest in
            guard let path = urlRequest.url?.path,
                  path.contains("/payment_pages/"),
                  path.hasSuffix("/confirm") else { return false }
            DispatchQueue.main.async {
                context.paymentAuthorizationControllerDidFinish(context.authorizationController)
            }
            return false
        } response: { _ in HTTPStubsResponse() }

        let didComplete = expectation(description: "Apple Pay completes despite cancel")
        Task {
            let result = await context.presentApplePay()
            // Then the payment still succeeds
            XCTAssertEqual(result.paymentSheetResult, .completed)
            didComplete.fulfill()
        }
        // When the user taps Pay (completion block is ignored — finishAndDismiss drives the result)
        context.paymentAuthorizationController(
            context.authorizationController,
            didAuthorizePayment: STPFixtures.simulatorApplePayPayment(),
            handler: { _ in }
        )
        await fulfillment(of: [didComplete], timeout: 20.0)
    }

    // MARK: - Helpers

    private func makeContext() async throws -> (CheckoutApplePayContext, STPAPIClient) {
        let returnURL = "stripe-ios-test://checkout-return"
        let sessionResponse = try await STPTestingAPIClient.shared.createCheckoutSession(
            customerEmailLocation: "test",
            returnURL: returnURL
        )
        let apiClient = STPAPIClient(publishableKey: sessionResponse.publishableKey)
        let initResponse = try await apiClient.initCheckoutSession(
            checkoutSessionId: sessionResponse.id,
            adaptivePricingAllowed: false
        )
        let dataSource = CheckoutApplePayContextFunctionalTestDataSource(
            session: initResponse.makePublicSession(),
            apiClient: apiClient,
            returnURL: returnURL
        )
        let context = CheckoutApplePayContext(
            checkout: dataSource,
            authorizationController: MockPKPaymentAuthorizationController(),
            authenticationContext: MockAuthContext()
        )
        return (context, apiClient)
    }

    /// Simulates the user tapping 'Pay': calls `didAuthorizePayment` and once the completion
    /// fires, calls `paymentAuthorizationControllerDidFinish`.
    func _startApplePayForContext(
        _ context: CheckoutApplePayContext,
        withExpectedStatus expectedStatus: PKPaymentAuthorizationStatus
    ) {
        let authorizationController = context.authorizationController
        context.paymentAuthorizationController(
            authorizationController,
            didAuthorizePayment: STPFixtures.simulatorApplePayPayment(),
            handler: { result in
                XCTAssertEqual(result.status, expectedStatus)
                DispatchQueue.main.async {
                    context.paymentAuthorizationControllerDidFinish(authorizationController)
                }
            }
        )
    }
}

// MARK: - Test doubles
private class MockPKPaymentAuthorizationController: PKPaymentAuthorizationController {
    override func present(completion: ((Bool) -> Void)? = nil) {
        completion?(true)
    }

    override func dismiss(completion: (() -> Void)? = nil) {
        completion?()
    }
}

@MainActor
private class CheckoutApplePayContextFunctionalTestDataSource: CheckoutConfirmDataSource {
    var applePayConfiguration: Checkout.ApplePayConfiguration? = Checkout.ApplePayConfiguration(merchantId: "merchant.com.test")
    let session: Checkout.Session
    let apiClient: STPAPIClient
    let paymentHandler: STPPaymentHandler
    var returnURL: String?
    let merchantDisplayName = "Functional Test Merchant"
    var expressCheckoutElementBillingDetailsCollectionConfiguration = ExpressCheckoutElement.Configuration.BillingDetailsCollectionConfiguration()

    init(session: Checkout.Session, apiClient: STPAPIClient, returnURL: String? = nil) {
        self.session = session
        self.apiClient = apiClient
        self.paymentHandler = STPPaymentHandler(apiClient: apiClient)
        self.returnURL = returnURL
    }

    func commitSession(_ response: PaymentPagesAPIResponse) async throws {}
}

private class MockAuthContext: NSObject, STPAuthenticationContext {
    func authenticationPresentingViewController() -> UIViewController {
        UIViewController()
    }
}
