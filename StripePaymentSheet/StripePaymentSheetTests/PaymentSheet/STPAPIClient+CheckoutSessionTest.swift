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
        // Fetch a fresh checkout session from the test backend
        let checkoutSessionResponse = try await STPTestingAPIClient.shared.fetchCheckoutSessionPaymentMode()
        let checkoutSessionId = checkoutSessionResponse.id

        let apiClient = STPAPIClient(publishableKey: checkoutSessionResponse.publishableKey)
        let checkoutSession = try await apiClient.initCheckoutSession(checkoutSessionId: checkoutSessionId, adaptivePricingAllowed: false)

        // Verify checkout session fields
        XCTAssertEqual(checkoutSession.id, checkoutSessionId)
        XCTAssertEqual(checkoutSession.mode, .payment)
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
        // 1. Fetch a checkout session from test backend
        let checkoutSessionResponse = try await STPTestingAPIClient.shared.fetchCheckoutSessionPaymentMode()
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
        // Fetch a checkout session with adaptive pricing enabled and DE customer location
        let checkoutSessionResponse = try await STPTestingAPIClient.shared.fetchCheckoutSessionPaymentMode(
            adaptivePricingEnabled: true,
            customerEmailLocation: "DE"
        )
        let checkoutSessionId = checkoutSessionResponse.id

        let apiClient = STPAPIClient(publishableKey: checkoutSessionResponse.publishableKey)
        let checkoutSession = try await apiClient.initCheckoutSession(checkoutSessionId: checkoutSessionId, adaptivePricingAllowed: true)

        // Verify standard checkout session fields
        XCTAssertEqual(checkoutSession.id, checkoutSessionId)
        XCTAssertEqual(checkoutSession.mode, .payment)
        XCTAssertEqual(checkoutSession.status?.type, .open)
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
        XCTAssertEqual(checkoutSession.id, checkoutSessionId)
        XCTAssertEqual(checkoutSession.mode, .payment)
        XCTAssertEqual(checkoutSession.status?.type, .open)
        XCTAssertFalse(checkoutSession.livemode)

        // Adaptive pricing should NOT be active; currency stays as integration currency (USD)
        XCTAssertFalse(checkoutSession.adaptivePricingActive)
        XCTAssertEqual(checkoutSession.currency, "usd")
        XCTAssertNil(checkoutSession.exchangeRateMeta)
        XCTAssertTrue(checkoutSession.localizedPricesMetas.isEmpty)
    }

    // MARK: - Update Payment Method

    func testUpdatePaymentMethodExpiry() async throws {
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
        let checkoutSessionResponse = try await STPTestingAPIClient.shared.fetchCheckoutSessionPaymentMode(
            customerID: customerResponse.customer,
            setupFutureUsage: "on_session"
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
        )

        // 5. Verify the session was returned successfully (proves the API accepted our request)
        XCTAssertEqual(updatedSession.id, checkoutSessionResponse.id)
        XCTAssertEqual(updatedSession.status?.type, .open)
    }

    func testUpdatePaymentMethodBillingDetails() async throws {
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
        let checkoutSessionResponse = try await STPTestingAPIClient.shared.fetchCheckoutSessionPaymentMode(
            customerID: customerResponse.customer,
            setupFutureUsage: "on_session"
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
        )

        // 5. Verify the session was returned successfully (proves the API accepted our request)
        XCTAssertEqual(updatedSession.id, checkoutSessionResponse.id)
        XCTAssertEqual(updatedSession.status?.type, .open)
    }

    // MARK: - Setup Mode

    func testInitCheckoutSessionSetup() async throws {
        // Fetch a fresh checkout session in setup mode from the test backend
        let checkoutSessionResponse = try await STPTestingAPIClient.shared.fetchCheckoutSessionSetupMode()
        let checkoutSessionId = checkoutSessionResponse.id

        let apiClient = STPAPIClient(publishableKey: checkoutSessionResponse.publishableKey)
        let checkoutSession = try await apiClient.initCheckoutSession(checkoutSessionId: checkoutSessionId, adaptivePricingAllowed: false)

        // Verify checkout session fields
        XCTAssertEqual(checkoutSession.id, checkoutSessionId)
        XCTAssertEqual(checkoutSession.mode, .setup)
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
        XCTAssertEqual(response.status?.type, .complete)
        XCTAssertEqual(response.status?.paymentStatus, .noPaymentRequired)
        XCTAssertNotNil(response.setupIntent)
    }
}
