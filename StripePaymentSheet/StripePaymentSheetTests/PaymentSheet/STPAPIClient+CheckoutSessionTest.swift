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
        let apiResponse = try await apiClient.initCheckoutSession(checkoutSessionId: checkoutSessionId, adaptivePricingAllowed: false)
        let checkoutSession = apiResponse.makePublicSession()

        // Verify checkout session fields
        XCTAssertEqual(checkoutSession.id, checkoutSessionId)
        XCTAssertEqual(checkoutSession.status?.type, .open)
        XCTAssertEqual(checkoutSession.status?.paymentStatus, .unpaid)
        XCTAssertEqual(checkoutSession.currency, "usd")
        XCTAssertFalse(checkoutSession.livemode)
        XCTAssertTrue((apiResponse.allResponseFields["payment_method_types"] as? [String])?.contains("card") ?? false)

        // Verify elements session fields
        let elementsSessionDict = apiResponse.allResponseFields["elements_session"] as! [String: Any]
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
        let expectedAmount = initResponse.makePublicSession().expectedAmount() ?? 0

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
        XCTAssertEqual(response.makePublicSession().status?.type, .complete)
        XCTAssertEqual(response.makePublicSession().status?.paymentStatus, .paid)
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
        let checkoutSession = try await apiClient.initCheckoutSession(checkoutSessionId: checkoutSessionId, adaptivePricingAllowed: true).makePublicSession()

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
        let checkoutSession = try await apiClient.initCheckoutSession(checkoutSessionId: checkoutSessionId, adaptivePricingAllowed: false).makePublicSession()

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

    // MARK: - Update Payment Method

    // TODO(porter): Checkout rejects `payment_method_to_update` on modeless sessions
    // ("This feature is not currently supported in our Product Catalog v2 private preview.").
    func disabled_testUpdatePaymentMethodExpiry() async throws {
        // 1. Create a customer and attach a card PM to them
        let customerResponse = try await STPTestingAPIClient.shared.fetchCustomerAndEphemeralKey()
        let apiClient = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)

        let cardParams = STPPaymentMethodCardParams()
        cardParams.number = "4242424242424242"
        cardParams.expMonth = 12
        cardParams.expYear = 2030
        cardParams.cvc = "123"
        let billingDetails = STPPaymentMethodBillingDetails()
        billingDetails.email = "test@example.com"
        let paymentMethodParams = STPPaymentMethodParams(card: cardParams, billingDetails: billingDetails, metadata: nil)
        let paymentMethod = try await apiClient.createPaymentMethod(with: paymentMethodParams)

        try await apiClient.attachPaymentMethod(
            paymentMethod.stripeId,
            customerID: customerResponse.customer,
            ephemeralKeySecret: customerResponse.ephemeralKeySecret
        )

        // 2. Create a checkout session for this customer
        let checkoutSessionResponse = try await STPTestingAPIClient.shared.createCheckoutSession(
            customerID: customerResponse.customer,
            additionalParameters: ["payment_intent_data": ["setup_future_usage": "on_session"]]
        )
        let sessionApiClient = STPAPIClient(publishableKey: checkoutSessionResponse.publishableKey)

        // 3. Init the session
        _ = try await sessionApiClient.initCheckoutSession(
            checkoutSessionId: checkoutSessionResponse.id,
            adaptivePricingAllowed: false
        )

        // 4. Update the attached PM's expiry via the checkout session
        let updatedSession = try await sessionApiClient.updatePaymentMethod(
            paymentMethod.stripeId,
            inCheckoutSession: checkoutSessionResponse.id,
            expiryDetails: Checkout.PaymentMethodExpiryDetails(expMonth: 6, expYear: 2029)
        ).makePublicSession()

        // 5. Verify the session was returned successfully (proves the API accepted our request)
        XCTAssertEqual(updatedSession.id, checkoutSessionResponse.id)
        XCTAssertEqual(updatedSession.status?.type, .open)
    }

    // TODO(porter): see disabled_testUpdatePaymentMethodExpiry above.
    func disabled_testUpdatePaymentMethodBillingDetails() async throws {
        // 1. Create a customer and attach a card PM to them
        let customerResponse = try await STPTestingAPIClient.shared.fetchCustomerAndEphemeralKey()
        let apiClient = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)

        let cardParams = STPPaymentMethodCardParams()
        cardParams.number = "4242424242424242"
        cardParams.expMonth = 12
        cardParams.expYear = 2030
        cardParams.cvc = "123"
        let billingDetails = STPPaymentMethodBillingDetails()
        billingDetails.email = "test@example.com"
        let paymentMethodParams = STPPaymentMethodParams(card: cardParams, billingDetails: billingDetails, metadata: nil)
        let paymentMethod = try await apiClient.createPaymentMethod(with: paymentMethodParams)

        try await apiClient.attachPaymentMethod(
            paymentMethod.stripeId,
            customerID: customerResponse.customer,
            ephemeralKeySecret: customerResponse.ephemeralKeySecret
        )

        // 2. Create a checkout session for this customer
        let checkoutSessionResponse = try await STPTestingAPIClient.shared.createCheckoutSession(
            customerID: customerResponse.customer,
            additionalParameters: ["payment_intent_data": ["setup_future_usage": "on_session"]]
        )
        let sessionApiClient = STPAPIClient(publishableKey: checkoutSessionResponse.publishableKey)

        // 3. Init the session
        _ = try await sessionApiClient.initCheckoutSession(
            checkoutSessionId: checkoutSessionResponse.id,
            adaptivePricingAllowed: false
        )

        // 4. Update the attached PM's billing details via the checkout session
        let updatedSession = try await sessionApiClient.updatePaymentMethod(
            paymentMethod.stripeId,
            inCheckoutSession: checkoutSessionResponse.id,
            billingDetails: Checkout.PaymentMethodBillingDetails(
                name: "Jane Doe",
                email: "jane@example.com",
                phone: "+15551234567",
                address: Checkout.PaymentMethodBillingAddress(
                    line1: "123 Main St",
                    city: "San Francisco",
                    state: "CA",
                    postalCode: "94105",
                    country: "US"
                )
            )
        ).makePublicSession()

        // 5. Verify the session was returned successfully (proves the API accepted our request)
        XCTAssertEqual(updatedSession.id, checkoutSessionResponse.id)
        XCTAssertEqual(updatedSession.status?.type, .open)
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
        let apiResponse = try await apiClient.initCheckoutSession(checkoutSessionId: checkoutSessionId, adaptivePricingAllowed: false)
        let checkoutSession = apiResponse.makePublicSession()

        // Verify checkout session fields
        XCTAssertEqual(checkoutSession.id, checkoutSessionId)
        XCTAssertEqual(checkoutSession.status?.type, .open)
        XCTAssertEqual(checkoutSession.status?.paymentStatus, .noPaymentRequired)
        XCTAssertEqual(checkoutSession.currency, "usd")
        XCTAssertFalse(checkoutSession.livemode)
        XCTAssertTrue((apiResponse.allResponseFields["payment_method_types"] as? [String])?.contains("card") ?? false)

        // Verify elements session fields
        let elementsSessionDict = apiResponse.allResponseFields["elements_session"] as! [String: Any]
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
        XCTAssertEqual(response.makePublicSession().status?.type, .complete)
        XCTAssertEqual(response.makePublicSession().status?.paymentStatus, .noPaymentRequired)
        XCTAssertNotNil(response.setupIntent)
    }
}
