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
@testable @_spi(InternalOnlyAPI) import StripeCore
@testable @_spi(InternalOnlyAPI) import StripeCoreTestUtils
@testable @_spi(InternalOnlyAPI) import StripePayments
@testable @_spi(InternalOnlyAPI) import StripePaymentSheet
import StripePaymentsObjcTestUtils
@testable @_spi(InternalOnlyAPI) import StripePaymentsTestUtils
import XCTest

@MainActor
class CheckoutApplePayContextFunctionalTest: STPNetworkStubbingTestCase {
    func testCompletesPayment() async throws {
        let (context, apiClient) = try await makeContext()

        let didComplete = expectation(description: "Apple Pay completes")
        Task {
            let result = await context.presentApplePay()
            XCTAssertEqual(result.paymentSheetResult, .completed)
            if case .completed(let response) = result {
                XCTAssertEqual(response.status, .complete(.paid))
                XCTAssertEqual(response.paymentIntent?.status, .succeeded)
            }
            didComplete.fulfill()
        }
        _startApplePayForContext(context, withExpectedStatus: .success)
        await fulfillment(of: [didComplete], timeout: STPTestingNetworkRequestTimeout)
        try await assertApplePayPaymentMethod(context: context, apiClient: apiClient)
    }

    func testCompletesSetupForZeroAmountSession() async throws {
        // Given a zero-amount Checkout Session with an Apple Pay payment
        let (context, apiClient) = try await makeContext(amount: 0)
        let didComplete = expectation(description: "Apple Pay setup completes")
        Task {
            let result = await context.presentApplePay()
            XCTAssertEqual(result.paymentSheetResult, .completed)
            if case .completed(let response) = result {
                XCTAssertEqual(response.status, .complete(.noPaymentRequired))
                XCTAssertEqual(response.setupIntent?.status, .succeeded)
            }
            didComplete.fulfill()
        }

        // When the customer authorizes Apple Pay
        _startApplePayForContext(context, withExpectedStatus: .success)

        // Then setup completes and preserves the wallet's payment method details
        await fulfillment(of: [didComplete], timeout: STPTestingNetworkRequestTimeout)
        try await assertApplePayPaymentMethod(context: context, apiClient: apiClient)
    }

    func testCancelAfterConfirmStillSucceeds() async throws {
        // Given a cancel fires while the confirm is in-flight
        let (context, _) = try await makeContext()
        let didCancel = expectation(description: "Cancellation happens during confirmation")
        var cancellationRequested = false
        stub { urlRequest in
            guard let path = urlRequest.url?.path,
                  path.contains("/checkout_client/"),
                  path.hasSuffix("/confirm") else { return false }
            DispatchQueue.main.async {
                guard !cancellationRequested else { return }
                cancellationRequested = true
                context.paymentAuthorizationControllerDidFinish(context.authorizationController)
                didCancel.fulfill()
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
        await fulfillment(of: [didCancel, didComplete], timeout: 20.0)
    }

    // MARK: - Helpers

    private func assertApplePayPaymentMethod(context: CheckoutApplePayContext, apiClient: STPAPIClient) async throws {
        guard case .completed(let response) = context.result else {
            return XCTFail("Expected a completed Checkout Session")
        }
        let paymentMethod: STPPaymentMethod?
        if let paymentIntent = response.paymentIntent {
            let intent = try await apiClient.retrievePaymentIntent(clientSecret: paymentIntent.clientSecret, expand: ["payment_method"])
            paymentMethod = intent.paymentMethod
        } else {
            let setupIntent = try XCTUnwrap(response.setupIntent)
            let intent = try await apiClient.retrieveSetupIntent(clientSecret: setupIntent.clientSecret, expand: ["payment_method"])
            paymentMethod = intent.paymentMethod
        }
        let confirmedPaymentMethod = try XCTUnwrap(paymentMethod)
        XCTAssertEqual(confirmedPaymentMethod.card?.wallet?.type, .applePay)
        XCTAssertEqual(confirmedPaymentMethod.billingDetails?.name, "Jane Doe")
        XCTAssertEqual(confirmedPaymentMethod.billingDetails?.email, "jane@example.com")
    }

    private func makeContext(amount: Int = 2000) async throws -> (CheckoutApplePayContext, STPAPIClient) {
        let returnURL = "stripe-ios-test://checkout-return"
        let sessionResponse = try await STPTestingAPIClient.shared.createCheckoutSession(
            amount: amount,
            customerEmailLocation: "test",
            returnURL: returnURL
        )
        let apiClient = STPAPIClient(publishableKey: sessionResponse.publishableKey)
        let initResponse = try await apiClient.initCheckoutSession(
            checkoutSessionId: sessionResponse.id,
            clientSecret: sessionResponse.clientSecret,
            adaptivePricingAllowed: false
        )
        let session = initResponse.makePublicSession(clientSecret: sessionResponse.clientSecret)
        let authenticationContext = WindowAuthenticationContext()
        let paymentHandler = STPPaymentHandler(apiClient: apiClient)
        let applePayConfirmationParameters = CheckoutController.ApplePayConfirmationParameters.makeMock(
            apiClient: apiClient,
            returnURL: returnURL,
            merchantDisplayName: "Functional Test Merchant",
            confirmationHandler: { requestParameters in
                await CheckoutController.confirmCheckoutSession(
                    with: requestParameters,
                    apiClient: apiClient,
                    authenticationContext: authenticationContext,
                    paymentHandler: paymentHandler
                )
            }
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
            didAuthorizePayment: STPFixtures.testPKPaymentWithContactDetails(),
            handler: { result in
                XCTAssertEqual(result.status, expectedStatus)
                DispatchQueue.main.async {
                    context.paymentAuthorizationControllerDidFinish(authorizationController)
                }
            }
        )
    }
}
