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

    func testInitCheckoutSessionPayment() async throws {
        // Create a fresh checkout session with the test backend
        let checkoutSessionResponse = try await STPTestingAPIClient.shared.createCheckoutSession()
        let checkoutSessionId = checkoutSessionResponse.id

        let apiClient = STPAPIClient(publishableKey: checkoutSessionResponse.publishableKey)
        let checkoutSession = try await apiClient.initCheckoutSession(checkoutSessionId: checkoutSessionId, adaptivePricingAllowed: false)

        // Verify checkout session fields
        XCTAssertEqual(checkoutSession.id, checkoutSessionId)
        XCTAssertEqual(checkoutSession.status?.type, .open)
        XCTAssertEqual(checkoutSession.status?.paymentStatus, .unpaid)
        XCTAssertEqual(checkoutSession.currency, "usd")
        XCTAssertFalse(checkoutSession.livemode)
        XCTAssertTrue((checkoutSession.allResponseFields["payment_method_types"] as? [String])?.contains("card") ?? false)

        // Verify elements session fields
        let elementsSessionDict = checkoutSession.allResponseFields["elements_session"] as! [String: Any]
        XCTAssertTrue((elementsSessionDict["session_id"] as! String).hasPrefix("elements_session_"))
        XCTAssertEqual(elementsSessionDict["merchant_country"] as? String, "US")
    }

    func testConfirmCheckoutSessionPayment() async throws {
        // 1. Create a checkout session with the test backend
        let checkoutSessionResponse = try await STPTestingAPIClient.shared.createCheckoutSession(
            returnURL: "stripe-ios-test://checkout-return"
        )
        let sessionId = checkoutSessionResponse.id

        let apiClient = STPAPIClient(publishableKey: checkoutSessionResponse.publishableKey)

        // 2. Init the checkout session to get the actual amount
        let initResponse = try await apiClient.initCheckoutSession(checkoutSessionId: sessionId, adaptivePricingAllowed: false)
        let expectedAmount = initResponse.total?.total.minorUnitsAmount ?? 0

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
        XCTAssertEqual(response.status?.type, .complete)
        XCTAssertEqual(response.status?.paymentStatus, .paid)
        XCTAssertNotNil(response.paymentIntent)
    }

    // MARK: - Adaptive Pricing

    func testInitCheckoutSessionPaymentWithAdaptivePricing() async throws {
        // Create a checkout session with a DE customer location (adaptive pricing no longer
        // needs to be requested on the session — it's active automatically). Uses the
        // `us_tax` test account, which has adaptive pricing enabled; the default `us`
        // account doesn't.
        let checkoutSessionResponse = try await STPTestingAPIClient.shared.createCheckoutSession(
            merchantCountry: "us_tax",
            customerEmailLocation: "DE"
        )
        let checkoutSessionId = checkoutSessionResponse.id

        let apiClient = STPAPIClient(publishableKey: checkoutSessionResponse.publishableKey)
        let checkoutSession = try await apiClient.initCheckoutSession(checkoutSessionId: checkoutSessionId, adaptivePricingAllowed: true)

        // Verify standard checkout session fields
        XCTAssertEqual(checkoutSession.id, checkoutSessionId)
        XCTAssertEqual(checkoutSession.status?.type, .open)
        XCTAssertFalse(checkoutSession.livemode)

        // Verify adaptive pricing is active and currency is localized to EUR
        XCTAssertTrue(checkoutSession.adaptivePricingActive)
        XCTAssertEqual(checkoutSession.currency, "eur")
        XCTAssertNotNil(checkoutSession.exchangeRateMeta)
        XCTAssertFalse(checkoutSession.localizedPricesMetas.isEmpty)
    }

    func testInitCheckoutSessionPaymentWithAdaptivePricingDisabled() async throws {
        // Same session config as above (DE location, adaptive pricing active automatically)
        // but client passes adaptivePricingAllowed: false
        let checkoutSessionResponse = try await STPTestingAPIClient.shared.createCheckoutSession(
            merchantCountry: "us_tax",
            customerEmailLocation: "DE"
        )
        let checkoutSessionId = checkoutSessionResponse.id

        let apiClient = STPAPIClient(publishableKey: checkoutSessionResponse.publishableKey)
        let checkoutSession = try await apiClient.initCheckoutSession(checkoutSessionId: checkoutSessionId, adaptivePricingAllowed: false)

        // Verify standard checkout session fields
        XCTAssertEqual(checkoutSession.id, checkoutSessionId)
        XCTAssertEqual(checkoutSession.status?.type, .open)
        XCTAssertFalse(checkoutSession.livemode)

        // Adaptive pricing should NOT be active; currency stays as integration currency (USD)
        XCTAssertFalse(checkoutSession.adaptivePricingActive)
        XCTAssertEqual(checkoutSession.currency, "usd")
        XCTAssertNil(checkoutSession.exchangeRateMeta)
        XCTAssertTrue(checkoutSession.localizedPricesMetas.isEmpty)
    }

    // MARK: - Setup Mode

    // TODO(porter): Setup mode is out of scope for unified-mode private preview.
    // Rename back to `test...` once unified mode supports setup mode — but note
    // `createCheckoutSession()` below creates a real payment-shaped modeless session, not
    // a setup-style one, so the assertions here (`.noPaymentRequired`, etc.) will need
    // reshaping too, not just the rename.
    func disabled_testInitCheckoutSessionSetup() async throws {
        // Create a fresh checkout session in setup mode with the test backend
        let checkoutSessionResponse = try await STPTestingAPIClient.shared.createCheckoutSession()
        let checkoutSessionId = checkoutSessionResponse.id

        let apiClient = STPAPIClient(publishableKey: checkoutSessionResponse.publishableKey)
        let checkoutSession = try await apiClient.initCheckoutSession(checkoutSessionId: checkoutSessionId, adaptivePricingAllowed: false)

        // Verify checkout session fields
        XCTAssertEqual(checkoutSession.id, checkoutSessionId)
        XCTAssertEqual(checkoutSession.status?.type, .open)
        XCTAssertEqual(checkoutSession.status?.paymentStatus, .noPaymentRequired)
        XCTAssertEqual(checkoutSession.currency, "usd")
        XCTAssertFalse(checkoutSession.livemode)
        XCTAssertTrue((checkoutSession.allResponseFields["payment_method_types"] as? [String])?.contains("card") ?? false)

        // Verify elements session fields
        let elementsSessionDict = checkoutSession.allResponseFields["elements_session"] as! [String: Any]
        XCTAssertTrue((elementsSessionDict["session_id"] as! String).hasPrefix("elements_session_"))
        XCTAssertEqual(elementsSessionDict["merchant_country"] as? String, "US")
    }

    // TODO(porter): see disabled_testInitCheckoutSessionSetup above.
    func disabled_testConfirmCheckoutSessionSetup() async throws {
        // 1. Create a checkout session in setup mode with the test backend
        let checkoutSessionResponse = try await STPTestingAPIClient.shared.createCheckoutSession()
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
        XCTAssertEqual(response.status?.type, .complete)
        XCTAssertEqual(response.status?.paymentStatus, .noPaymentRequired)
        XCTAssertNotNil(response.setupIntent)
    }
}
