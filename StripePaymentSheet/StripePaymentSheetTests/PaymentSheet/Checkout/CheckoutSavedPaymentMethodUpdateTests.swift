//
//  CheckoutSavedPaymentMethodUpdateTests.swift
//  StripePaymentSheetTests
//
//  Created by George Birch on 11/18/26.
//

import OHHTTPStubs
@testable @_spi(InternalOnlyAPI) import StripePayments
@testable @_spi(InternalOnlyAPI) @_spi(CheckoutSessionPreview) import StripePaymentSheet
import XCTest

@MainActor
final class CheckoutSavedPaymentMethodUpdateTests: XCTestCase {

    private let sessionID = "cs_test_123"

    override func tearDown() {
        HTTPStubs.removeAllStubs()
        super.tearDown()
    }

    func testRemovedSavedPaymentMethodStaysRemovedAfterLocalUpdate() async throws {
        // Given a Customer with one saved card, which the server removes when asked
        let (checkout, recorder) = try await makeCheckout(
            initialPaymentMethods: [savedCardJSON()],
            updatedPaymentMethods: []
        )
        let embedded = try XCTUnwrap(checkout.paymentElement).embeddedPaymentElement
        let card = try XCTUnwrap(embedded.savedPaymentMethods.first)

        // When the customer removes the card in Payment Element and the server finishes removing it
        embedded.loadResult.customerProvider.detach(
            paymentMethod: card,
            elementsSession: embedded.elementsSession,
            apiClient: embedded.configuration.apiClient
        )
        try await waitUntil {
            recorder.requests.contains { $0.params["payment_method_to_detach"] == card.stripeId }
        }
        try await checkout.awaitPendingOperations()
        // ...and the merchant then makes an update that doesn't call the server, which rebuilds Payment Element
        try await checkout.updateShippingAddress(
            name: "Jenny Rosen",
            address: .init(country: "US", line1: "354 Oyster Point Blvd")
        )

        // Then the card was removed once, and the rebuilt Payment Element doesn't bring it back
        let updateRequests = recorder.requests.filter { $0.kind == .updateSession }
        XCTAssertEqual(updateRequests.map { $0.params["payment_method_to_detach"] }, [card.stripeId])
        XCTAssertFalse(embedded.savedPaymentMethods.contains { $0.stripeId == card.stripeId })
    }

    func testEditedSavedPaymentMethodKeepsEditAfterLocalUpdate() async throws {
        // Given a Customer with one saved card that expires 12/2040, which the server changes to 11/2041 when asked
        let (checkout, _) = try await makeCheckout(
            initialPaymentMethods: [savedCardJSON(expMonth: 12, expYear: 2040)],
            updatedPaymentMethods: [savedCardJSON(expMonth: 11, expYear: 2041)]
        )
        let embedded = try XCTUnwrap(checkout.paymentElement).embeddedPaymentElement
        let card = try XCTUnwrap(embedded.savedPaymentMethods.first)
        let cardParams = STPPaymentMethodCardParams()
        cardParams.expMonth = 11
        cardParams.expYear = 2041

        // When the customer changes the card's expiry in Payment Element
        let updatedCard = try await embedded.loadResult.customerProvider.update(
            paymentMethod: card,
            with: STPPaymentMethodUpdateParams(card: cardParams, billingDetails: nil),
            elementsSession: embedded.elementsSession,
            apiClient: embedded.configuration.apiClient
        )
        XCTAssertEqual(updatedCard.card?.expMonth, 11)
        // ...and the merchant then makes an update that doesn't call the server, which rebuilds Payment Element
        try await checkout.updateShippingAddress(
            name: "Jenny Rosen",
            address: .init(country: "US", line1: "354 Oyster Point Blvd")
        )

        // Then the rebuilt Payment Element keeps the edited expiry
        let rebuiltCard = embedded.savedPaymentMethods.first { $0.stripeId == card.stripeId }
        XCTAssertEqual(rebuiltCard?.card?.expMonth, 11)
        XCTAssertEqual(rebuiltCard?.card?.expYear, 2041)
    }
}

private extension CheckoutSavedPaymentMethodUpdateTests {

    /// Loads a Checkout controller with Payment Element. Its `/update` responses carry `updatedPaymentMethods`.
    /// The session has no automatic tax, so shipping updates don't call the server.
    func makeCheckout(
        initialPaymentMethods: [[String: Any]],
        updatedPaymentMethods: [[String: Any]]
    ) async throws -> (CheckoutElementsController, CheckoutSessionRequestRecorder) {
        let initialSessionJSON = sessionJSON(paymentMethods: initialPaymentMethods)
        let updatedSessionJSON = sessionJSON(paymentMethods: updatedPaymentMethods)
        // Also stubs every other request Payment Element makes while loading, such as Link lookups
        let configuration = CheckoutTestHelpers.makeConfiguration(
            apiResponse: try CheckoutClientAPIResponse.decode(fromAPIResponse: initialSessionJSON),
            expressCheckoutElementConfiguration: nil
        )
        // Stubbed after the configuration so these take precedence over its default Checkout stubs
        let recorder = CheckoutSessionRequestRecorder()
        CheckoutTestHelpers.stubCheckoutSessionRequests(
            sessionId: sessionID,
            requestRecorder: recorder,
            sessionJSON: {
                recorder.requests.last?.kind == .updateSession ? updatedSessionJSON : initialSessionJSON
            }
        )
        return (try await CheckoutElementsController(configuration: configuration), recorder)
    }

    func sessionJSON(paymentMethods: [[String: Any]]) -> [String: Any] {
        CheckoutTestHelpers.makeSessionJSON([
            "id": sessionID,
            "customer": ["id": "cus_test", "payment_methods": paymentMethods],
        ])
    }

    func savedCardJSON(expMonth: Int = 12, expYear: Int = 2040) -> [String: Any] {
        [
            "id": "pm_saved_card",
            "type": "card",
            "created": "12345",
            "card": [
                "last4": "4242",
                "brand": "visa",
                "exp_month": expMonth,
                "exp_year": expYear,
            ],
        ]
    }

    func waitUntil(
        timeout: TimeInterval = 5,
        file: StaticString = #filePath,
        line: UInt = #line,
        _ condition: () -> Bool
    ) async throws {
        let deadline = Date().addingTimeInterval(timeout)
        while !condition() {
            guard Date() < deadline else {
                XCTFail("Condition not met within \(timeout) seconds", file: file, line: line)
                throw CheckoutError.timedOut
            }
            try await Task.sleep(nanoseconds: 1_000_000)
        }
    }
}
