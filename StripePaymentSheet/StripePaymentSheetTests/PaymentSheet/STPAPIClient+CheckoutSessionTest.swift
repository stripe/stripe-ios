//
//  STPAPIClient+CheckoutSessionTest.swift
//  StripePaymentSheetTests
//
//  Created by Nick Porter on 1/15/26.
//

@testable @_spi(STP) import StripeCore
@testable @_spi(STP) import StripeCoreTestUtils
@testable @_spi(STP) import StripePayments
@testable @_spi(STP) @_spi(CheckoutSessionsPreview) import StripePaymentSheet
@testable @_spi(STP) import StripePaymentsTestUtils
import XCTest

final class STPAPIClientCheckoutSessionTest: STPNetworkStubbingTestCase {

    func testInitCheckoutSessionPayment() async throws {
        // Fetch a fresh checkout session from the test backend
        let checkoutSessionResponse = try await STPTestingAPIClient.shared.fetchCheckoutSessionPaymentMode()
        let checkoutSessionId = checkoutSessionResponse.id

        let apiClient = STPAPIClient(publishableKey: checkoutSessionResponse.publishableKey)
        let checkoutSession = try await apiClient.initCheckoutSession(checkoutSessionId: checkoutSessionId, adaptivePricingAllowed: false)

        // Verify checkout session fields
        XCTAssertEqual(checkoutSession.stripeId, checkoutSessionId)
        XCTAssertEqual(checkoutSession.mode, .payment)
        XCTAssertEqual(checkoutSession.status, .open)
        XCTAssertEqual(checkoutSession.paymentStatus, .unpaid)
        XCTAssertEqual(checkoutSession.currency, "usd")
        XCTAssertFalse(checkoutSession.livemode)
        XCTAssertTrue(checkoutSession.paymentMethodTypes.contains(.card))

        // Verify elements session fields
        let elementsSessionDict = checkoutSession.allResponseFields["elements_session"] as! [String: Any]
        XCTAssertTrue((elementsSessionDict["session_id"] as! String).hasPrefix("elements_session_"))
        XCTAssertEqual(elementsSessionDict["merchant_country"] as? String, "US")
    }

    func testConfirmCheckoutSessionPayment() async throws {
        // 1. Fetch a checkout session from test backend
        let checkoutSessionResponse = try await STPTestingAPIClient.shared.fetchCheckoutSessionPaymentMode()
        let sessionId = checkoutSessionResponse.id

        let apiClient = STPAPIClient(publishableKey: checkoutSessionResponse.publishableKey)

        // 2. Init the checkout session to get the actual amount
        let initResponse = try await apiClient.initCheckoutSession(checkoutSessionId: sessionId, adaptivePricingAllowed: false)
        let expectedAmount = initResponse.totals?.total ?? 0

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

    // MARK: - Adaptive Pricing

    func testInitCheckoutSessionPaymentWithAdaptivePricing() async throws {
        // Fetch a checkout session with adaptive pricing enabled and DE customer location
        let checkoutSessionResponse = try await STPTestingAPIClient.shared.fetchCheckoutSessionPaymentMode(
            adaptivePricingEnabled: true,
            customerEmailLocation: "DE"
        )
        let checkoutSessionId = checkoutSessionResponse.id

        let apiClient = STPAPIClient(publishableKey: checkoutSessionResponse.publishableKey)
        let checkoutSession = try await apiClient.initCheckoutSession(checkoutSessionId: checkoutSessionId, adaptivePricingAllowed: true)

        // Verify standard checkout session fields
        XCTAssertEqual(checkoutSession.stripeId, checkoutSessionId)
        XCTAssertEqual(checkoutSession.mode, .payment)
        XCTAssertEqual(checkoutSession.status, .open)
        XCTAssertFalse(checkoutSession.livemode)

        // Verify adaptive pricing is active and currency is localized to EUR
        XCTAssertTrue(checkoutSession.adaptivePricingActive)
        XCTAssertEqual(checkoutSession.currency, "eur")
        XCTAssertNotNil(checkoutSession.exchangeRateMeta)
        XCTAssertFalse(checkoutSession.localizedPricesMetas.isEmpty)
    }

    func testInitCheckoutSessionPaymentWithAdaptivePricingDisabled() async throws {
        // Same session config as above (adaptive pricing enabled on backend, DE location)
        // but client passes adaptivePricingAllowed: false
        let checkoutSessionResponse = try await STPTestingAPIClient.shared.fetchCheckoutSessionPaymentMode(
            adaptivePricingEnabled: true,
            customerEmailLocation: "DE"
        )
        let checkoutSessionId = checkoutSessionResponse.id

        let apiClient = STPAPIClient(publishableKey: checkoutSessionResponse.publishableKey)
        let checkoutSession = try await apiClient.initCheckoutSession(checkoutSessionId: checkoutSessionId, adaptivePricingAllowed: false)

        // Verify standard checkout session fields
        XCTAssertEqual(checkoutSession.stripeId, checkoutSessionId)
        XCTAssertEqual(checkoutSession.mode, .payment)
        XCTAssertEqual(checkoutSession.status, .open)
        XCTAssertFalse(checkoutSession.livemode)

        // Adaptive pricing should NOT be active; currency stays as integration currency (USD)
        XCTAssertFalse(checkoutSession.adaptivePricingActive)
        XCTAssertEqual(checkoutSession.currency, "usd")
        XCTAssertNil(checkoutSession.exchangeRateMeta)
        XCTAssertTrue(checkoutSession.localizedPricesMetas.isEmpty)
    }

    // MARK: - Setup Mode

    func testInitCheckoutSessionSetup() async throws {
        // Fetch a fresh checkout session in setup mode from the test backend
        let checkoutSessionResponse = try await STPTestingAPIClient.shared.fetchCheckoutSessionSetupMode()
        let checkoutSessionId = checkoutSessionResponse.id

        let apiClient = STPAPIClient(publishableKey: checkoutSessionResponse.publishableKey)
        let checkoutSession = try await apiClient.initCheckoutSession(checkoutSessionId: checkoutSessionId, adaptivePricingAllowed: false)

        // Verify checkout session fields
        XCTAssertEqual(checkoutSession.stripeId, checkoutSessionId)
        XCTAssertEqual(checkoutSession.mode, .setup)
        XCTAssertEqual(checkoutSession.status, .open)
        XCTAssertEqual(checkoutSession.paymentStatus, .noPaymentRequired)
        XCTAssertEqual(checkoutSession.currency, "usd")
        XCTAssertFalse(checkoutSession.livemode)
        XCTAssertTrue(checkoutSession.paymentMethodTypes.contains(.card))

        // Verify elements session fields
        let elementsSessionDict = checkoutSession.allResponseFields["elements_session"] as! [String: Any]
        XCTAssertTrue((elementsSessionDict["session_id"] as! String).hasPrefix("elements_session_"))
        XCTAssertEqual(elementsSessionDict["merchant_country"] as? String, "US")
    }

    func testConfirmCheckoutSessionSetup() async throws {
        // 1. Fetch a checkout session in setup mode from test backend
        let checkoutSessionResponse = try await STPTestingAPIClient.shared.fetchCheckoutSessionSetupMode()
        let sessionId = checkoutSessionResponse.id

        let apiClient = STPAPIClient(publishableKey: checkoutSessionResponse.publishableKey)

        // 2. Init the checkout session
        _ = try await apiClient.initCheckoutSession(checkoutSessionId: sessionId, adaptivePricingAllowed: false)

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

        // 4. Confirm the checkout session (no expected amount for setup mode)
        let response = try await apiClient.confirmCheckoutSession(
            sessionId: sessionId,
            paymentMethod: paymentMethod.stripeId,
            expectedAmount: nil,
            expectedPaymentMethodType: "card"
        )

        // 5. Verify response
        XCTAssertEqual(response.status, .complete)
        XCTAssertEqual(response.paymentStatus, .noPaymentRequired)
        XCTAssertNotNil(response.setupIntent)
    }
}
