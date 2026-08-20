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
@testable @_spi(STP) import StripeCoreTestUtils
@testable @_spi(STP) import StripePayments
@testable @_spi(STP) import StripePaymentSheet
import StripePaymentsObjcTestUtils
import XCTest

@MainActor
final class CheckoutApplePayContextTests: XCTestCase {

    override func tearDown() {
        HTTPStubs.removeAllStubs()
        super.tearDown()
    }

    // MARK: - makeSummaryItems

    func testMakeSummaryItemsWithAmount() {
        // Given a session with a known total
        let session = CheckoutTestHelpers.makeSession([
            "checkout_items": CheckoutTestHelpers.makeOneTimePriceCheckoutItems(unitAmount: 2500),
            "currency": "usd",
        ]).makePublicSession()

        // When
        let items = CheckoutApplePayContext.makeSummaryItems(for: session, label: "Test Store")

        // Then it returns a single final item with the correct amount
        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items[0].label, "Test Store")
        XCTAssertEqual(items[0].type, .final)
        XCTAssertEqual(items[0].amount, NSDecimalNumber.stp_decimalNumber(withAmount: 2500, currency: "usd"))
    }

    func testMakeSummaryItemsWithNoAmount() {
        // Given a no-payment-required session (e.g. free order)
        let session = CheckoutTestHelpers.makeSession(["payment_status": "no_payment_required"]).makePublicSession()

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
        context.result = .failed(error)

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
        context.paymentState = .success
        context.result = .completed(try! PaymentPagesAPIResponse.decode(fromAPIResponse: makeConfirmResponseJSON()))

        // When the sheet is dismissed
        let resultTask = Task { await context.presentApplePay() }
        await Task.yield()
        context.paymentAuthorizationControllerDidFinish(mockController)

        // Then the result is .completed
        let result = await resultTask.value
        XCTAssertEqual(result.paymentSheetResult, .completed)
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
        let session = response.makePublicSession()
        let applePayConfirmationParameters = CheckoutController.ApplePayConfirmationParameters.makeMock(apiClient: resolvedAPIClient)
        let mockController = MockPKPaymentAuthorizationController()
        let context = CheckoutApplePayContext(
            checkoutSession: session,
            applePayConfirmationParameters: applePayConfirmationParameters,
            authorizationController: mockController
        )
        return (context, mockController)
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
            "mode": "modeless",
            "currency": "usd",
            "checkout_items": CheckoutTestHelpers.makeOneTimePriceCheckoutItems(),
            "status": "complete",
            "payment_status": "paid",
            "payment_method_types": ["card"],
            "elements_session": CheckoutTestHelpers.minimalElementsSessionJSON,
            "payment_intent": paymentIntentJSON,
        ]
        json["client_secret"] = "cs_test_123_secret_abc"
        return json
    }

}
