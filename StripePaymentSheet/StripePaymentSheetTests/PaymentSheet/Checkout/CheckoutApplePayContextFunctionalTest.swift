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
        let session = initResponse.makePublicSession()
        let applePayConfirmationParameters = CheckoutController.ApplePayConfirmationParameters.makeMock(
            apiClient: apiClient,
            returnURL: returnURL,
            merchantDisplayName: "Functional Test Merchant"
        )
        let context = CheckoutApplePayContext(
            checkoutSession: session,
            applePayConfirmationParameters: applePayConfirmationParameters,
            authorizationController: MockPKPaymentAuthorizationController(),
            checkoutWalletUpdater: MockCheckoutSessionWalletUpdater()
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
