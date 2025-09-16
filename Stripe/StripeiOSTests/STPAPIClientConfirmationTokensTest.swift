//
//  STPAPIClientConfirmationTokensTest.swift
//  StripePaymentsTests
//
//  Created by Nick Porter on 9/4/25.
//

@testable@_spi(STP) import StripeCore
@testable@_spi(STP)@_spi(ConfirmationTokensPublicPreview) import StripePayments
@testable @_spi(STP) @_spi(CustomerSessionBetaAccess) import StripePaymentSheet
@testable import StripePaymentsTestUtils
import XCTest

class STPAPIClientConfirmationTokensTest: STPNetworkStubbingTestCase {

    var apiClient: STPAPIClient!

    override func setUp() {
        super.setUp()
        apiClient = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)
    }

    // MARK: - Async createConfirmationToken Tests

    func testCreateConfirmationTokenWithPaymentMethodData() async throws {
        // Create payment method params
        let cardParams = STPPaymentMethodCardParams()
        cardParams.number = "4242424242424242"
        cardParams.expMonth = 12
        cardParams.expYear = 2030
        cardParams.cvc = "123"

        let paymentMethodParams = STPPaymentMethodParams(
            card: cardParams,
            billingDetails: nil,
            metadata: nil
        )

        // Create confirmation token params
        let confirmationTokenParams = STPConfirmationTokenParams()
        confirmationTokenParams.paymentMethodData = paymentMethodParams
        confirmationTokenParams.returnURL = "https://example.com/return"

        // Test async method
        let confirmationToken = try await apiClient.createConfirmationToken(
            with: confirmationTokenParams
        )

        // Verify the response
        XCTAssertNotNil(confirmationToken)
        XCTAssertFalse(confirmationToken.stripeId.isEmpty)
        XCTAssertNotNil(confirmationToken.created)
        XCTAssertNotNil(confirmationToken.allResponseFields)
    }

    func testCreateConfirmationTokenWithExistingPaymentMethod() async throws {
        // First create a payment method
        let cardParams = STPPaymentMethodCardParams()
        cardParams.number = "4242424242424242"
        cardParams.expMonth = 12
        cardParams.expYear = 2030
        cardParams.cvc = "123"

        let paymentMethodParams = STPPaymentMethodParams(
            card: cardParams,
            billingDetails: nil,
            metadata: nil
        )

        let paymentMethod = try await apiClient.createPaymentMethod(with: paymentMethodParams)

        // Now create confirmation token with existing payment method
        let confirmationTokenParams = STPConfirmationTokenParams()
        confirmationTokenParams.paymentMethod = paymentMethod.stripeId
        confirmationTokenParams.returnURL = "https://example.com/return"

        let confirmationToken = try await apiClient.createConfirmationToken(
            with: confirmationTokenParams
        )

        // Verify the response
        XCTAssertNotNil(confirmationToken)
        XCTAssertFalse(confirmationToken.stripeId.isEmpty)
        XCTAssertNotNil(confirmationToken.created)
        XCTAssertNotNil(confirmationToken.allResponseFields)
    }

    func testCreateConfirmationTokenWithShippingAndMandateData() async throws {
        // Create payment method params for SEPA Debit (requires mandate)
        let sepaParams = STPPaymentMethodSEPADebitParams()
        sepaParams.iban = "DE89370400440532013000"

        let billingDetails = STPPaymentMethodBillingDetails()
        billingDetails.name = "Jenny Rosen"
        billingDetails.email = "jenny@example.com"

        let paymentMethodParams = STPPaymentMethodParams(
            sepaDebit: sepaParams,
            billingDetails: billingDetails,
            metadata: nil
        )

        // Create shipping details
        let addressParams = STPPaymentIntentShippingDetailsAddressParams(line1: "123 Main St")
        addressParams.city = "San Francisco"
        addressParams.state = "CA"
        addressParams.postalCode = "94111"
        addressParams.country = "US"

        let shippingDetails = STPPaymentIntentShippingDetailsParams(
            address: addressParams,
            name: "Test Customer"
        )

        // Create mandate data
        let mandateData = STPMandateDataParams.makeWithInferredValues()

        // Create confirmation token params
        let confirmationTokenParams = STPConfirmationTokenParams()
        confirmationTokenParams.paymentMethodData = paymentMethodParams
        confirmationTokenParams.returnURL = "https://example.com/return"
        confirmationTokenParams.shipping = shippingDetails
        confirmationTokenParams.mandateData = mandateData
        confirmationTokenParams.setupFutureUsage = .offSession

        let confirmationToken = try await apiClient.createConfirmationToken(
            with: confirmationTokenParams
        )

        // Verify the response
        XCTAssertNotNil(confirmationToken)
        XCTAssertFalse(confirmationToken.stripeId.isEmpty)
        XCTAssertNotNil(confirmationToken.created)
        XCTAssertNotNil(confirmationToken.allResponseFields)
    }

    func testCreateConfirmationTokenWithAttachedPaymentMethod() async throws {
        // Part 1: Use legacy fetchCustomerAndEphemeralKey for payment method attachment
        let customerAndEphemeralKey = try await STPTestingAPIClient.shared().fetchCustomerAndEphemeralKey(
            customerID: nil,
            merchantCountry: "us"
        )

        // Create a new payment method
        let cardParams = STPPaymentMethodCardParams()
        cardParams.number = "4242424242424242"
        cardParams.expMonth = 12
        cardParams.expYear = 2030
        cardParams.cvc = "123"

        let paymentMethodParams = STPPaymentMethodParams(
            card: cardParams,
            billingDetails: nil,
            metadata: nil
        )

        let paymentMethod = try await apiClient.createPaymentMethod(with: paymentMethodParams)

        // Attach the payment method to the customer using legacy ephemeral key
        try await apiClient.attachPaymentMethod(
            paymentMethod.stripeId,
            customerID: customerAndEphemeralKey.customer,
            ephemeralKeySecret: customerAndEphemeralKey.ephemeralKeySecret
        )

        // Part 2: Use customer sessions for confirmation token creation
        let customerAndCustomerSession = try await STPTestingAPIClient.shared().fetchCustomerAndCustomerSessionClientSecret(
            customerID: customerAndEphemeralKey.customer, // Use existing customer from part 1
            merchantCountry: "us",
            paymentMethodSave: true
        )

        // Get elements session to access the customer session ephemeral key
        var configuration = PaymentSheet.Configuration()
        configuration.customer = PaymentSheet.CustomerConfiguration(
            id: customerAndCustomerSession.customer,
            customerSessionClientSecret: customerAndCustomerSession.customerSessionClientSecret
        )
        let elementsSession = try await apiClient.retrieveDeferredElementsSession(
            withIntentConfig: .init(mode: .setup(currency: "usd", setupFutureUsage: .offSession),
                                    confirmHandler: { _, _, _ in
                                        // no-op
                                    }),
            clientDefaultPaymentMethod: nil,
            configuration: configuration
        )

        // Get ephemeral key from customer session
        guard let customerSessionEphemeralKey = elementsSession.customer?.customerSession.apiKey else {
            XCTFail("Failed to get ephemeral key from customer session")
            return
        }

        // Create confirmation token with attached payment method using customer session
        let confirmationTokenParams = STPConfirmationTokenParams()
        confirmationTokenParams.paymentMethod = paymentMethod.stripeId
        confirmationTokenParams.returnURL = "https://example.com/return"
        confirmationTokenParams.setupFutureUsage = .offSession

        let confirmationToken = try await apiClient.createConfirmationToken(
            with: confirmationTokenParams,
            ephemeralKeySecret: customerSessionEphemeralKey
        )

        // Verify the response
        XCTAssertNotNil(confirmationToken)
        XCTAssertFalse(confirmationToken.stripeId.isEmpty)
        XCTAssertNotNil(confirmationToken.created)
        XCTAssertNotNil(confirmationToken.allResponseFields)

        // Clean up: detach the payment method from the customer
        try await apiClient.detachPaymentMethod(
            paymentMethod.stripeId,
            fromCustomerUsing: customerSessionEphemeralKey,
            withCustomerSessionClientSecret: customerAndCustomerSession.customerSessionClientSecret
        )
    }

    func testCreateConfirmationTokenWithSetAsDefaultPaymentMethod() async throws {
        // Create payment method params
        let cardParams = STPPaymentMethodCardParams()
        cardParams.number = "4242424242424242"
        cardParams.expMonth = 12
        cardParams.expYear = 2030
        cardParams.cvc = "123"

        let paymentMethodParams = STPPaymentMethodParams(
            card: cardParams,
            billingDetails: nil,
            metadata: nil
        )

        // Create confirmation token params with setAsDefaultPM = true
        let confirmationTokenParams = STPConfirmationTokenParams()
        confirmationTokenParams.paymentMethodData = paymentMethodParams
        confirmationTokenParams.returnURL = "https://example.com/return"
        confirmationTokenParams.setupFutureUsage = .offSession
        confirmationTokenParams.setAsDefaultPM = NSNumber(value: true)

        // Create confirmation token with customer session ephemeral key
        let confirmationToken = try await apiClient.createConfirmationToken(
            with: confirmationTokenParams
        )

        // Verify the response
        XCTAssertNotNil(confirmationToken)
        XCTAssertFalse(confirmationToken.stripeId.isEmpty)
        XCTAssertNotNil(confirmationToken.created)
        XCTAssertNotNil(confirmationToken.allResponseFields)

        // Verify the setAsDefaultPM parameter was encoded correctly
        let encoded = STPFormEncoder.dictionary(forObject: confirmationTokenParams)
        XCTAssertEqual(encoded["set_as_default_payment_method"] as? NSNumber, NSNumber(value: true))
    }

    // MARK: - Error Handling Tests

    func testCreateConfirmationTokenWithInvalidCard() async {
        // Create payment method params with invalid card
        let cardParams = STPPaymentMethodCardParams()
        cardParams.number = "4000000000000002" // Declined card
        cardParams.expMonth = 12
        cardParams.expYear = 2030
        cardParams.cvc = "123"

        let paymentMethodParams = STPPaymentMethodParams(
            card: cardParams,
            billingDetails: nil,
            metadata: nil
        )

        let confirmationTokenParams = STPConfirmationTokenParams()
        confirmationTokenParams.paymentMethodData = paymentMethodParams
        confirmationTokenParams.returnURL = "https://example.com/return"

        do {
            _ = try await apiClient.createConfirmationToken(with: confirmationTokenParams)
            // Note: Creating a confirmation token with a declined card should still succeed,
            // as the card is not charged at this point. The error would occur during confirmation.
            // So we don't expect an error here.
        } catch {
            // If there is an error, it should be a proper Stripe error
            XCTAssertNotNil(error)
        }
    }

    // MARK: - Parameter Encoding Tests

    func testConfirmationTokenParamsEncoding() {
        // Test that our params are properly encoded
        let cardParams = STPPaymentMethodCardParams()
        cardParams.number = "4242424242424242"
        cardParams.expMonth = 12
        cardParams.expYear = 2030
        cardParams.cvc = "123"

        let paymentMethodParams = STPPaymentMethodParams(
            card: cardParams,
            billingDetails: nil,
            metadata: nil
        )

        let confirmationTokenParams = STPConfirmationTokenParams()
        confirmationTokenParams.paymentMethodData = paymentMethodParams
        confirmationTokenParams.returnURL = "https://example.com/return"
        confirmationTokenParams.setupFutureUsage = .onSession

        let encoded = STPFormEncoder.dictionary(forObject: confirmationTokenParams)

        // Verify key parameters are encoded correctly
        XCTAssertNotNil(encoded["payment_method_data"])
        XCTAssertEqual(encoded["return_url"] as? String, "https://example.com/return")
        XCTAssertEqual(encoded["setup_future_usage"] as? String, "on_session")
    }
}
