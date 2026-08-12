//
//  CheckoutApplePayContextTests.swift
//  StripePaymentSheetTests
//
//  Created by Joyce Qin on 8/3/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

import OHHTTPStubs
import OHHTTPStubsSwift
import PassKit
@testable @_spi(STP) import StripeCore
@testable @_spi(STP) import StripePayments
import StripePaymentsObjcTestUtils
@testable @_spi(STP) import StripePaymentSheet
@testable @_spi(STP) import StripeCoreTestUtils
import XCTest

@MainActor
final class CheckoutApplePayContextTests: XCTestCase {

    override func tearDown() {
        HTTPStubs.removeAllStubs()
        super.tearDown()
    }

    // MARK: - makeSummaryItems

    func testMakeSummaryItemsWithAmount() {
        // Given a session with a known total (2500 = $25.00 in USD)
        let response = CheckoutTestHelpers.makeSession([
            "total_summary": ["subtotal": 2500, "total": 2500, "due": 2500],
            "currency": "usd",
        ])
        let session = response.makePublicSession()

        // When
        let items = CheckoutApplePayContext.makeSummaryItems(for: session, label: "Test Store")

        // Then it returns a single final item with the correct amount
        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items[0].label, "Test Store")
        XCTAssertEqual(items[0].type, .final)
        XCTAssertEqual(items[0].amount, NSDecimalNumber.stp_decimalNumber(withAmount: 2500, currency: "usd"))
    }

    func testMakeSummaryItemsWithNoAmount() {
        // Given a session with no amount (free / not-yet-known)
        let response = CheckoutTestHelpers.makeSession()
        let session = response.makePublicSession()

        // When
        let items = CheckoutApplePayContext.makeSummaryItems(for: session, label: "Test Store")

        // Then it returns a pending item with zero amount
        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items[0].label, "Test Store")
        XCTAssertEqual(items[0].type, .pending)
        XCTAssertEqual(items[0].amount, .zero)
    }

    // MARK: - paymentAuthorizationControllerDidFinish state machine

    func testDidFinish_notStarted_cancels() async {
        // Given a context in the .notStarted state
        let (context, mockController) = makeContext()

        // When the sheet is dismissed before the user pays
        let resultTask = Task { await context.presentApplePay() }
        await Task.yield()
        context.paymentAuthorizationControllerDidFinish(mockController)

        // Then the result is .canceled
        let result = await resultTask.value
        XCTAssertEqual(result.paymentSheetResult, .canceled)
    }

    func testDidFinish_pending_setsDeferFlag() {
        // Given a context in the .pending state (payment is in-flight)
        let (context, mockController) = makeContext()
        context.paymentState = .pending

        // When the user cancels while pending
        context.paymentAuthorizationControllerDidFinish(mockController)

        // Then it defers the dismiss instead of canceling immediately
        XCTAssertTrue(context.didCancelOrTimeoutWhilePending)
    }

    func testDidFinish_error_returnsError() async {
        // Given a context that finished with an error
        let (context, mockController) = makeContext()
        let error = CheckoutError.unknown(debugDescription: "test error")
        context.paymentState = .error
        context.result = .init(paymentSheetResult: .failed(error: error))

        // When the sheet is dismissed
        let resultTask = Task { await context.presentApplePay() }
        await Task.yield()
        context.paymentAuthorizationControllerDidFinish(mockController)

        // Then the result is .failed
        let result = await resultTask.value
        if case .failed = result.paymentSheetResult {
            // expected
        } else {
            XCTFail("Expected .failed, got \(result.paymentSheetResult)")
        }
    }

    func testDidFinish_success_returnsSuccess() async {
        // Given a context that finished with success
        let (context, mockController) = makeContext()
        let confirmResponse = makeConfirmResponse()
        context.paymentState = .success
        context.result = .init(paymentSheetResult: .completed, checkoutSessionResponse: confirmResponse)

        // When the sheet is dismissed
        let resultTask = Task { await context.presentApplePay() }
        await Task.yield()
        context.paymentAuthorizationControllerDidFinish(mockController)

        // Then the result is .completed
        let result = await resultTask.value
        XCTAssertEqual(result.paymentSheetResult, .completed)
    }

    // MARK: - Full confirm flows

    func testSuccessFlow() async {
        // Given a context with stubbed APIs that return a succeeded payment intent
        let sessionId = "cs_test_123"
        let apiClient = CheckoutTestHelpers.makeStubbedAPIClient()
        stubPaymentMethodCreation()
        stubConfirmSession(sessionId: sessionId, succeeded: true)

        let (context, _) = makeContext(sessionId: sessionId, apiClient: apiClient)

        // When the user taps Pay and the flow completes
        let resultTask = Task { await context.presentApplePay() }
        await Task.yield()
        _startApplePayForContext(context, withExpectedStatus: .success)

        let e = expectation(description: "Apple Pay completes")
        Task {
            let result = await resultTask.value
            XCTAssertEqual(result.paymentSheetResult, .completed)
            e.fulfill()
        }
        await fulfillment(of: [e], timeout: 10)
    }

    func testFailureFlow() async {
        // Given a context where confirm returns an error
        let sessionId = "cs_test_123"
        let apiClient = CheckoutTestHelpers.makeStubbedAPIClient()
        stubPaymentMethodCreation()
        stubConfirmSession(sessionId: sessionId, succeeded: false)

        let (context, _) = makeContext(sessionId: sessionId, apiClient: apiClient)

        // When the user taps Pay and confirm fails
        let resultTask = Task { await context.presentApplePay() }
        await Task.yield()
        _startApplePayForContext(context, withExpectedStatus: .failure)

        let e = expectation(description: "Apple Pay fails")
        Task {
            let result = await resultTask.value
            if case .failed = result.paymentSheetResult {
                // expected
            } else {
                XCTFail("Expected .failed, got \(result.paymentSheetResult)")
            }
            e.fulfill()
        }
        await fulfillment(of: [e], timeout: 10)
    }

    func testCancelWhilePendingThenFailureReturnsError() async {
        // Given a context where confirm fails and a cancel arrives mid-confirm
        let sessionId = "cs_test_123"
        let apiClient = CheckoutTestHelpers.makeStubbedAPIClient()
        stubPaymentMethodCreation()
        stubConfirmSession(sessionId: sessionId, succeeded: false)
        let (context, mockController) = makeContext(sessionId: sessionId, apiClient: apiClient)

        // ...and a side-effect-only stub that fires paymentAuthorizationControllerDidFinish
        // as soon as the confirm request is intercepted, then returns false so the failure
        // stub above still handles the actual response.
        stub(condition: { $0.url?.path == "/v1/payment_pages/\(sessionId)/confirm" }) { _ in
            DispatchQueue.main.async {
                context.paymentAuthorizationControllerDidFinish(mockController)
            }
            return false
        } response: { _ in HTTPStubsResponse() }

        // When the user taps Pay (the PKPaymentAuthorizationResult handler is never called
        // because handleFailure takes the finishAndDismiss path, not the completion path)
        let resultTask = Task { await context.presentApplePay() }
        await Task.yield()
        context.paymentAuthorizationController(
            context.authorizationController,
            didAuthorizePayment: STPFixtures.simulatorApplePayPayment(),
            handler: { _ in }
        )

        // Then the result is .failed — not .canceled, because the payment already reached .pending
        let e = expectation(description: "Apple Pay fails after cancel-while-pending")
        Task {
            let result = await resultTask.value
            if case .failed = result.paymentSheetResult {
                // expected
            } else {
                XCTFail("Expected .failed, got \(result.paymentSheetResult)")
            }
            e.fulfill()
        }
        await fulfillment(of: [e], timeout: 10)
    }

    // MARK: - Helpers

    private func makeContext(
        sessionId: String = "cs_test_123",
        apiClient: STPAPIClient? = nil
    ) -> (CheckoutApplePayContext, MockPKPaymentAuthorizationController) {
        let resolvedAPIClient = apiClient ?? APIStubbedTestCase.stubbedAPIClient()
        let response = CheckoutTestHelpers.makeSession([
            "session_id": sessionId,
            "currency": "usd",
            "total_summary": ["subtotal": 1000, "total": 1000, "due": 1000],
        ])
        let dataSource = MockCheckoutConfirmDataSource(session: response.makePublicSession(), apiClient: resolvedAPIClient)
        let mockController = MockPKPaymentAuthorizationController()
        let authContext = MockAuthenticationContext()
        let context = CheckoutApplePayContext(
            checkout: dataSource,
            authorizationController: mockController,
            authenticationContext: authContext
        )
        return (context, mockController)
    }

    /// Simulates the user tapping Pay: calls `didAuthorizePayment`, and once the completion fires, calls `didFinish`.
    private func _startApplePayForContext(
        _ context: CheckoutApplePayContext,
        withExpectedStatus expectedStatus: PKPaymentAuthorizationStatus
    ) {
        let authController = context.authorizationController
        context.paymentAuthorizationController(
            authController,
            didAuthorizePayment: STPFixtures.simulatorApplePayPayment(),
            handler: { result in
                XCTAssertEqual(result.status, expectedStatus)
                DispatchQueue.main.async {
                    context.paymentAuthorizationControllerDidFinish(authController)
                }
            }
        )
    }

    private func stubPaymentMethodCreation() {
        stub(condition: { $0.url?.path == "/v1/payment_methods" }) { _ in
            let json = STPFixtures.applePayPaymentMethodJSON()
            let data = try! JSONSerialization.data(withJSONObject: json)
            return HTTPStubsResponse(data: data, statusCode: 200, headers: nil)
        }
    }

    private func stubConfirmSession(sessionId: String, succeeded: Bool) {
        stub(condition: { $0.url?.path == "/v1/payment_pages/\(sessionId)/confirm" }) { _ in
            if succeeded {
                let json = self.makeConfirmResponseJSON()
                let data = try! JSONSerialization.data(withJSONObject: json)
                return HTTPStubsResponse(data: data, statusCode: 200, headers: nil)
            } else {
                let errorJSON: [String: Any] = [
                    "error": [
                        "type": "card_error",
                        "message": "Your card was declined.",
                        "code": "card_declined",
                    ],
                ]
                let data = try! JSONSerialization.data(withJSONObject: errorJSON)
                return HTTPStubsResponse(data: data, statusCode: 402, headers: nil)
            }
        }
    }

    private func makeConfirmResponseJSON() -> [String: Any] {
        let paymentIntentJSON: [String: Any] = [
            "id": "pi_test_123",
            "object": "payment_intent",
            "amount": 1000,
            "currency": "usd",
            "status": "succeeded",
            "livemode": false,
            "created": 1234567890,
            "payment_method_types": ["card"],
            "client_secret": "pi_test_123_secret_abc",
        ]
        var json: [String: Any] = [
            "session_id": "cs_test_123",
            "object": "checkout.session",
            "livemode": false,
            "mode": "payment",
            "payment_status": "paid",
            "payment_method_types": ["card"],
            "elements_session": CheckoutTestHelpers.minimalElementsSessionJSON,
            "payment_intent": paymentIntentJSON,
        ]
        json["client_secret"] = "cs_test_123_secret_abc"
        return json
    }

    private func makeConfirmResponse() -> PaymentPagesAPIResponse {
        PaymentPagesAPIResponse.decodedObject(fromAPIResponse: makeConfirmResponseJSON())!
    }
}

// MARK: - Mocks

private class MockPKPaymentAuthorizationController: PKPaymentAuthorizationController {
    override func present(completion: ((Bool) -> Void)? = nil) {
        completion?(true)
    }

    override func dismiss(completion: (() -> Void)? = nil) {
        completion?()
    }
}

private class MockAuthenticationContext: NSObject, STPAuthenticationContext {
    func authenticationPresentingViewController() -> UIViewController {
        return UIViewController()
    }
}

@MainActor
private class MockCheckoutConfirmDataSource: CheckoutConfirmDataSource {
    var applePayConfiguration: Checkout.ApplePayConfiguration?
    let session: Checkout.Session
    let apiClient: STPAPIClient
    let paymentHandler: STPPaymentHandler
    var returnURL: String?
    let merchantDisplayName: String

    init(session: Checkout.Session, apiClient: STPAPIClient) {
        self.session = session
        self.apiClient = apiClient
        self.paymentHandler = STPPaymentHandler(apiClient: apiClient)
        self.merchantDisplayName = "Test Merchant"
        self.applePayConfiguration = Checkout.ApplePayConfiguration(merchantId: "merchant.com.test")
    }

    func commitSession(_ response: PaymentPagesAPIResponse) async throws {}
}
