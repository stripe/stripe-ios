//
//  STPAPIClient+CheckoutSessionTest.swift
//  StripePaymentSheetTests
//
//  Created by Nick Porter on 1/15/26.
//

@testable @_spi(STP) import StripeCore
@testable @_spi(STP) import StripeCoreTestUtils
@testable @_spi(STP) import StripePayments
@testable @_spi(STP) import StripePaymentSheet
@testable @_spi(STP) import StripePaymentsTestUtils
import XCTest

final class STPAPIClientCheckoutSessionTest: STPNetworkStubbingTestCase {

    func testInitCheckoutSession() async throws {
        // Fetch a fresh checkout session from the test backend
        let checkoutSessionResponse = try await STPTestingAPIClient.shared.fetchCheckoutSession()
        let checkoutSessionId = checkoutSessionResponse.id

        let apiClient = STPAPIClient(publishableKey: checkoutSessionResponse.publishableKey)
        let response = try await apiClient.initCheckoutSession(checkoutSessionId: checkoutSessionId)

        // Verify checkout session fields
        let checkoutSession = response.checkoutSession
        XCTAssertEqual(checkoutSession.stripeId, checkoutSessionId)
        XCTAssertEqual(checkoutSession.mode, .payment)
        XCTAssertEqual(checkoutSession.status, .open)
        XCTAssertEqual(checkoutSession.paymentStatus, .unpaid)
        XCTAssertEqual(checkoutSession.currency, "usd")
        XCTAssertFalse(checkoutSession.livemode)
        XCTAssertTrue(checkoutSession.paymentMethodTypes.contains(.card))

        // Verify elements session fields
        let elementsSession = response.elementsSession
        XCTAssertTrue(elementsSession.sessionID.hasPrefix("elements_session_"))
        XCTAssertEqual(elementsSession.merchantCountryCode, "US")
        XCTAssertTrue(elementsSession.orderedPaymentMethodTypes.contains(.card))
    }

    func testConfirmCheckoutSession() async throws {
        // 1. Fetch a checkout session from test backend
        let checkoutSessionResponse = try await STPTestingAPIClient.shared.fetchCheckoutSession()
        let sessionId = checkoutSessionResponse.id

        let apiClient = STPAPIClient(publishableKey: checkoutSessionResponse.publishableKey)

        // 2. Init the checkout session to get the actual amount
        let initResponse = try await apiClient.initCheckoutSession(checkoutSessionId: sessionId)
        let expectedAmount = initResponse.checkoutSession.totalSummary?.total ?? 0

        // 3. Create a payment method with test card and billing email
        let cardParams = STPPaymentMethodCardParams()
        cardParams.number = "4242424242424242"
        cardParams.expMonth = 12
        cardParams.expYear = 2030
        cardParams.cvc = "123"
        let billingDetails = STPPaymentMethodBillingDetails()
        billingDetails.email = "test@example.com"
        let paymentMethodParams = STPPaymentMethodParams(card: cardParams, billingDetails: billingDetails, metadata: nil)
        let paymentMethod = try await apiClient.createPaymentMethod(with: paymentMethodParams)

        // 4. Confirm the checkout session
        let response = try await apiClient.confirmCheckoutSession(
            sessionId: sessionId,
            paymentMethod: paymentMethod.stripeId,
            expectedAmount: expectedAmount,
            expectedPaymentMethodType: "card"
        )

        // 5. Verify response
        XCTAssertEqual(response.status, .complete)
        XCTAssertEqual(response.paymentStatus, .paid)
        XCTAssertNotNil(response.paymentIntent)
    }
}
