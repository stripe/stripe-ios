//
//  CheckoutApplePayContextTests.swift
//  StripePaymentSheetTests
//
//  Created by Joyce Qin on 8/3/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

import Contacts
import OHHTTPStubs
import OHHTTPStubsSwift
import PassKit
@testable @_spi(STP) import StripeCore
@testable @_spi(STP) import StripeCoreTestUtils
@testable @_spi(STP) import StripePayments
@testable @_spi(STP) import StripePaymentSheet
import StripePaymentsObjcTestUtils
import UIKit
import XCTest

@MainActor
final class CheckoutApplePayContextTests: XCTestCase {

    override func tearDown() {
        HTTPStubs.removeAllStubs()
        super.tearDown()
    }

    // MARK: - makeSummaryItems

    func testMakeSummaryItemsWithAmount() {
        // Given a session with a single item and no tax
        let session = CheckoutTestHelpers.makeSession([
            "checkout_items": CheckoutTestHelpers.makeOneTimePriceCheckoutItems(unitAmount: 2500),
            "currency": "usd",
        ]).makePublicSession()

        // When
        let items = CheckoutApplePayContext.makeSummaryItems(for: session, label: "Test Store")

        // Then it returns the item row and a grand total, with no breakdown rows
        XCTAssertEqual(items.count, 2)
        XCTAssertEqual(items[0].label, "Test product")
        XCTAssertEqual(items[0].amount, NSDecimalNumber.stp_decimalNumber(withAmount: 2500, currency: "usd"))
        XCTAssertEqual(items[1].label, "Test Store")
        XCTAssertEqual(items[1].type, .final)
        XCTAssertEqual(items[1].amount, NSDecimalNumber.stp_decimalNumber(withAmount: 2500, currency: "usd"))
    }

    func testMakeSummaryItemsWithLineItemsAndBreakdown() {
        // Given a session with two line items and tax on one of them
        let session = CheckoutTestHelpers.makeSession([
            "currency": "usd",
            "checkout_items": [
                [
                    "key": "checkout_item_widget",
                    "type": "one_time_price",
                    "one_time_price": [
                        "items": [
                            [
                                "inner_item_key": "widget",
                                "quantity": 1,
                                "subtotal": 2000,
                                "total": 2200,
                                "unit_amount": 2000,
                                "unit_amount_decimal": "2000",
                                "tax_amounts": [],
                                "tax_inclusive": 0,
                                "tax_exclusive": 200,
                                "price": ["id": "price_widget", "currency": "usd", "unit_amount": 2000, "product": ["name": "Widget", "images": []]],
                            ],
                        ],
                        "subtotal": 2000,
                        "total": 2200,
                    ],
                ],
                [
                    "key": "checkout_item_gadget",
                    "type": "one_time_price",
                    "one_time_price": [
                        "items": [
                            [
                                "inner_item_key": "gadget",
                                "quantity": 2,
                                "subtotal": 1000,
                                "total": 1000,
                                "unit_amount": 500,
                                "unit_amount_decimal": "500",
                                "tax_amounts": [],
                                "tax_inclusive": 0,
                                "tax_exclusive": 0,
                                "price": ["id": "price_gadget", "currency": "usd", "unit_amount": 500, "product": ["name": "Gadget", "images": []]],
                            ],
                        ],
                        "subtotal": 1000,
                        "total": 1000,
                    ],
                ],
            ],
        ]).makePublicSession()

        // When
        let items = CheckoutApplePayContext.makeSummaryItems(for: session, label: "Test Store")

        // Then it returns line items, subtotal, tax, and a grand total (discount rows are unsupported in unified mode)
        XCTAssertEqual(items.count, 5)
        XCTAssertEqual(items[0].label, "Widget")
        XCTAssertEqual(items[0].amount, NSDecimalNumber.stp_decimalNumber(withAmount: 2000, currency: "usd"))
        XCTAssertEqual(items[1].label, "Gadget ×2")
        XCTAssertEqual(items[1].amount, NSDecimalNumber.stp_decimalNumber(withAmount: 1000, currency: "usd"))
        XCTAssertEqual(items[2].label, String.Localized.subtotal)
        XCTAssertEqual(items[2].amount, NSDecimalNumber.stp_decimalNumber(withAmount: 3000, currency: "usd"))
        XCTAssertEqual(items[3].label, String.Localized.tax)
        XCTAssertEqual(items[3].amount, NSDecimalNumber.stp_decimalNumber(withAmount: 200, currency: "usd"))
        XCTAssertEqual(items[4].label, "Test Store")
        XCTAssertEqual(items[4].amount, NSDecimalNumber.stp_decimalNumber(withAmount: 3200, currency: "usd"))
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

    // MARK: - presentationWindow

    func testPresentationWindowReturnsConfiguredWindow() {
        // Given
        let presentationWindow = UIWindow()
        let (context, authorizationController) = makeContext(presentationWindow: presentationWindow)

        // When
        let returnedWindow = context.presentationWindow(for: authorizationController)

        // Then
        XCTAssertIdentical(returnedWindow, presentationWindow)
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

    // MARK: - didSelectPaymentMethod (billing tax region)

    func testDidSelectPaymentMethod_whenNotCollectingTaxFromBilling_doesNotUpdate() {
        // Given a context whose session does not source tax from the billing address
        let updater = MockCheckoutSessionWalletUpdater()
        let (context, mockController) = makeTaxContext(
            collectsTaxFromBillingAddress: false,
            checkout: updater
        )
        let paymentMethod = MockPKPaymentMethod(billingAddress: makeBillingContact())

        // When
        let expectation = expectation(description: "handler called")
        context.paymentAuthorizationController(mockController, didSelectPaymentMethod: paymentMethod) { _ in
            expectation.fulfill()
        }

        // Then the updater is never consulted
        waitForExpectations(timeout: 1)
        XCTAssertEqual(updater.updateCallCount, 0)
    }

    func testDidSelectPaymentMethod_withoutBillingAddress_doesNotUpdate() {
        // Given a session that sources tax from billing, but the selected payment method has no billing address
        let updater = MockCheckoutSessionWalletUpdater()
        let (context, mockController) = makeTaxContext(
            collectsTaxFromBillingAddress: true,
            checkout: updater
        )
        let paymentMethod = MockPKPaymentMethod(billingAddress: nil)

        // When
        let expectation = expectation(description: "handler called")
        context.paymentAuthorizationController(mockController, didSelectPaymentMethod: paymentMethod) { _ in
            expectation.fulfill()
        }

        // Then the updater is never consulted
        waitForExpectations(timeout: 1)
        XCTAssertEqual(updater.updateCallCount, 0)
    }

    func testDidSelectPaymentMethod_whenCheckoutHasBeenDeallocated_doesNotUpdate() {
        // Given a session that sources tax from billing, but the CheckoutSessionWalletUpdater is only
        // weakly held by the context and nothing else keeps it alive (e.g. its owning CheckoutController
        // has been deallocated)
        let (context, mockController) = makeTaxContext(
            collectsTaxFromBillingAddress: true,
            checkout: MockCheckoutSessionWalletUpdater()
        )
        let paymentMethod = MockPKPaymentMethod(billingAddress: makeBillingContact())

        // When it should not crash and should still call the handler
        let expectation = expectation(description: "handler called")
        context.paymentAuthorizationController(mockController, didSelectPaymentMethod: paymentMethod) { update in
            XCTAssertFalse(update.paymentSummaryItems.isEmpty)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1)
    }

    func testDidSelectPaymentMethod_whenCollectingTaxFromBilling_updatesSessionAndSummaryItems() {
        // Given a session that sources tax from billing, and an updater that returns a session with a new total
        let updatedSession = CheckoutTestHelpers.makeSession([
            "session_id": "cs_test_123",
            "currency": "usd",
            "checkout_items": CheckoutTestHelpers.makeOneTimePriceCheckoutItems(unitAmount: 1500),
        ]).makePublicSession()
        let updater = MockCheckoutSessionWalletUpdater(sessionToReturn: updatedSession)
        let (context, mockController) = makeTaxContext(
            collectsTaxFromBillingAddress: true,
            checkout: updater
        )
        let paymentMethod = MockPKPaymentMethod(billingAddress: makeBillingContact(country: "US"))

        // When
        let expectation = expectation(description: "handler called")
        var receivedUpdate: PKPaymentRequestPaymentMethodUpdate?
        context.paymentAuthorizationController(mockController, didSelectPaymentMethod: paymentMethod) { update in
            receivedUpdate = update
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1)

        // Then the updater was called with the billing address and the sheet-presented flag
        XCTAssertEqual(updater.updateCallCount, 1)
        XCTAssertEqual(updater.lastAddress?.country, "US")
        XCTAssertEqual(updater.lastCanUpdateWhileSheetPresented, true)

        // ...and the handler's summary items reflect the updated session's new total
        XCTAssertEqual(
            receivedUpdate?.paymentSummaryItems.last?.amount,
            NSDecimalNumber.stp_decimalNumber(withAmount: 1500, currency: "usd")
        )
    }

    func testDidSelectPaymentMethod_whenUpdateThrows_stillCallsHandler() {
        // Given an updater that fails to update the tax region
        let updater = MockCheckoutSessionWalletUpdater(errorToThrow: CheckoutError.unknown(debugDescription: "test error"))
        let (context, mockController) = makeTaxContext(
            collectsTaxFromBillingAddress: true,
            checkout: updater
        )
        let paymentMethod = MockPKPaymentMethod(billingAddress: makeBillingContact())

        // When it should still call the handler rather than hanging
        let expectation = expectation(description: "handler called")
        context.paymentAuthorizationController(mockController, didSelectPaymentMethod: paymentMethod) { update in
            XCTAssertFalse(update.paymentSummaryItems.isEmpty)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1)
        XCTAssertEqual(updater.updateCallCount, 1)
    }

    // MARK: - Helpers

    private func makeTaxContext(
        collectsTaxFromBillingAddress: Bool,
        checkout: CheckoutSessionWalletUpdater
    ) -> (CheckoutApplePayContext, MockPKPaymentAuthorizationController) {
        let response = CheckoutTestHelpers.makeSession([
            "session_id": "cs_test_123",
            "currency": "usd",
            "checkout_items": CheckoutTestHelpers.makeOneTimePriceCheckoutItems(unitAmount: 1000),
            "tax_context": [
                "automatic_tax_enabled": collectsTaxFromBillingAddress,
                "automatic_tax_address_source": "session.billing",
            ],
        ])
        let session = response.makePublicSession()
        let applePayConfirmationParameters = CheckoutController.ApplePayConfirmationParameters.makeMock(
            apiClient: APIStubbedTestCase.stubbedAPIClient()
        )
        let mockController = MockPKPaymentAuthorizationController()
        let context = CheckoutApplePayContext(
            checkoutSession: session,
            applePayConfirmationParameters: applePayConfirmationParameters,
            authorizationController: mockController,
            checkout: checkout
        )
        return (context, mockController)
    }

    private func makeBillingContact(country: String = "US") -> CNContact {
        let contact = CNMutableContact()
        let address = CNMutablePostalAddress()
        address.isoCountryCode = country
        address.city = "San Francisco"
        address.state = "CA"
        address.postalCode = "94105"
        contact.postalAddresses = [CNLabeledValue(label: CNLabelHome, value: address)]
        return contact
    }

    private func makeContext(
        sessionId: String = "cs_test_123",
        apiClient: STPAPIClient? = nil,
        presentationWindow: UIWindow? = nil
    ) -> (CheckoutApplePayContext, MockPKPaymentAuthorizationController) {
        let resolvedAPIClient = apiClient ?? APIStubbedTestCase.stubbedAPIClient()
        let response = CheckoutTestHelpers.makeSession([
            "session_id": sessionId,
            "currency": "usd",
            "total_summary": ["subtotal": 1000, "total": 1000, "due": 1000],
        ])
        let session = response.makePublicSession()
        let applePayConfirmationParameters = CheckoutController.ApplePayConfirmationParameters.makeMock(
            apiClient: resolvedAPIClient,
            presentationWindow: presentationWindow
        )
        let mockController = MockPKPaymentAuthorizationController()
        let context = CheckoutApplePayContext(
            checkoutSession: session,
            applePayConfirmationParameters: applePayConfirmationParameters,
            authorizationController: mockController,
            checkout: MockCheckoutSessionWalletUpdater()
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

// MARK: - Test doubles

private final class MockPKPaymentMethod: PKPaymentMethod {
    private let mockBillingAddress: CNContact?

    init(billingAddress: CNContact?) {
        self.mockBillingAddress = billingAddress
        super.init()
    }

    override var billingAddress: CNContact? { mockBillingAddress }
}
