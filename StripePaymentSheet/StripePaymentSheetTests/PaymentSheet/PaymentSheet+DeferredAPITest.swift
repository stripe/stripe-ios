//
//  PaymentSheet+DeferredAPITest.swift
//  StripePaymentSheetTests
//
//  Created by Nick Porter on 10/11/23.
//

@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripeCoreTestUtils
@testable@_spi(STP) import StripePayments
@testable@_spi(STP) @_spi(SharedPaymentToken) @_spi(PaymentMethodOptionsSetupFutureUsagePreview) import StripePaymentSheet
@testable@_spi(STP) import StripePaymentsTestUtils
@testable@_spi(STP) import StripeUICore
import XCTest

final class PaymentSheet_DeferredAPITest: STPNetworkStubbingTestCase {
    var apiClient: STPAPIClient!
    lazy var paymentHandler = STPPaymentHandler(apiClient: apiClient)
    override func setUp() {
        super.setUp()
        apiClient = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)
    }

    lazy var configuration: PaymentSheet.Configuration = {
        var config = PaymentSheet.Configuration()
        config.apiClient = apiClient
        config.allowsDelayedPaymentMethods = true
        config.shippingDetails = {
            return .init(
                address: .init(
                    country: "US",
                    line1: "Line 1"
                ),
                name: "Jane Doe",
                phone: "5551234567"
            )
        }
        return config
    }()

    // MARK: Helpers
    func createValidSavedPaymentMethod() -> STPPaymentMethod {
        var validSavedPM: STPPaymentMethod?
        let createPMExpectation = expectation(description: "Create PM")
        apiClient.createPaymentMethod(with: ._testValidCardValue()) { paymentMethod, error in
            guard let paymentMethod = paymentMethod else {
                XCTFail(String(describing: error))
                return
            }
            validSavedPM = paymentMethod
            createPMExpectation.fulfill()
        }
        waitForExpectations(timeout: 10)
        return validSavedPM!
    }

    // MARK: - PMO SFU test

    func testPMOSFUAndShouldSavePaymentMethodAreSet() async throws {
        // This tests that...
        // 1. For client-side confirmation, we set the PMO SFU value of the IntentConfiguration on /confirm
        // 2. For server-side confirmation, we set `shouldSavePaymentMethod` to `true` if PMO SFU is set.
        // Note - we don't send shouldSavePM = true to the server b/c then it will write PMO SFU, and we want to test that our own /confirm call sets PMO SFU.
        let clientSecret = try await STPTestingAPIClient.shared.fetchPaymentIntent(types: ["card"], currency: "USD", amount: 100, shouldSavePM: false, customerID: nil)

        // Given an IntentConfiguration that sets PMO SFU on card...
        let intentConfig = PaymentSheet.IntentConfiguration(
            mode: .payment(
                amount: 100,
                currency: "USD",
                paymentMethodOptions: .init(setupFutureUsageValues: [.card: .offSession])
            )
        ) { _, shouldSavePaymentMethod in
                // shouldSavePaymentMethod should be true because the intent configuration says to save the card.
                // This is necessary b/c server-side confirmation integrations are the ones confirming the Intent.
                XCTAssertTrue(shouldSavePaymentMethod)
                return clientSecret
            }

        let expectation = expectation(description: "Confirm intent")
        // When we confirm the Intent...
        let examplePaymentMethodParams = STPPaymentMethodParams(card: STPFixtures.paymentMethodCardParams(), billingDetails: nil, metadata: nil)
        PaymentSheet.handleDeferredIntentConfirmation(
            confirmType: .new(params: examplePaymentMethodParams, paymentOptions: .init(), paymentMethod: nil, shouldSave: false, shouldSetAsDefaultPM: nil),
            configuration: configuration,
            intentConfig: intentConfig,
            authenticationContext: TestAuthenticationContext(),
            paymentHandler: paymentHandler,
            isFlowController: false
        ) { _, _ in
            expectation.fulfill()
        }
        await fulfillment(of: [expectation])

        // ...the PaymentIntent should have PMO SFU set.
        let paymentIntent = try await apiClient.retrievePaymentIntent(clientSecret: clientSecret)
        XCTAssertEqual(paymentIntent.paymentMethodOptions?.setupFutureUsage(for: .card), "off_session")
        XCTAssertEqual(paymentIntent.setupFutureUsage, .none)
    }

    /// Unit test for `getShouldSavePaymentMethodValue(for:intentConfiguration:)`
    func testGetShouldSavePaymentMethodValue() {
        // If PMO SFU for the PM type is set, use that value:
        let intentConfigWithPMOSFUOffSession = PaymentSheet.IntentConfiguration(
            mode: .payment(
                amount: 100,
                currency: "USD",
                setupFutureUsage: nil,  // This should be overridden by PMO SFU
                paymentMethodOptions: .init(setupFutureUsageValues: [.card: .offSession])
            )
        ) { _, _ in return "" }

        XCTAssertTrue(PaymentSheet.getShouldSavePaymentMethodValue(for: .card, intentConfiguration: intentConfigWithPMOSFUOffSession))

        let intentConfigWithPMOSFUOnSession = PaymentSheet.IntentConfiguration(
            mode: .payment(
                amount: 100,
                currency: "USD",
                paymentMethodOptions: .init(setupFutureUsageValues: [.card: .onSession])
            )
        ) { _, _ in return "" }

        XCTAssertTrue(PaymentSheet.getShouldSavePaymentMethodValue(for: .card, intentConfiguration: intentConfigWithPMOSFUOnSession))

        let intentConfigWithPMOSFUNone = PaymentSheet.IntentConfiguration(
            mode: .payment(
                amount: 100,
                currency: "USD",
                paymentMethodOptions: .init(setupFutureUsageValues: [.card: .none])
            )
        ) { _, _ in return "" }

        XCTAssertFalse(PaymentSheet.getShouldSavePaymentMethodValue(for: .card, intentConfiguration: intentConfigWithPMOSFUNone))

        // If top-level SFU is set w/o any PMO SFU value, use that value
        let intentConfigWithTopLevelSFUOffSession = PaymentSheet.IntentConfiguration(
            mode: .payment(
                amount: 100,
                currency: "USD",
                setupFutureUsage: .offSession
            )
        ) { _, _ in return "" }

        XCTAssertTrue(PaymentSheet.getShouldSavePaymentMethodValue(for: .card, intentConfiguration: intentConfigWithTopLevelSFUOffSession))

        let intentConfigWithTopLevelSFUOnSession = PaymentSheet.IntentConfiguration(
            mode: .payment(
                amount: 100,
                currency: "USD",
                setupFutureUsage: .onSession
            )
        ) { _, _ in return "" }

        XCTAssertTrue(PaymentSheet.getShouldSavePaymentMethodValue(for: .card, intentConfiguration: intentConfigWithTopLevelSFUOnSession))

        // If nothing is set, don't set SFU
        let intentConfigWithoutSFU = PaymentSheet.IntentConfiguration(
            mode: .payment(amount: 100, currency: "USD")
        ) { _, _ in return "" }

        XCTAssertFalse(PaymentSheet.getShouldSavePaymentMethodValue(for: .card, intentConfiguration: intentConfigWithoutSFU))

        // Test that setup mode always returns false
        let setupIntentConfig = PaymentSheet.IntentConfiguration(
            mode: .setup(currency: "USD", setupFutureUsage: .offSession)
        ) { _, _ in return "" }

        XCTAssertFalse(PaymentSheet.getShouldSavePaymentMethodValue(for: .card, intentConfiguration: setupIntentConfig))
    }

    /// Unit test for `setSetupFutureUsage(for:intentConfiguration:on:)
    func testSetSetupFutureUsage() {
        // When PMO SFU is set and SFU is not set...
        let intentConfigWithPMOSFU = PaymentSheet.IntentConfiguration(
            mode: .payment(
                amount: 100,
                currency: "USD",
                paymentMethodOptions: .init(setupFutureUsageValues: [.card: .offSession])
            )
        ) { _, _ in return "" }

        // ...PMO SFU should be set on the params
        let paymentIntentParams = STPPaymentIntentParams(clientSecret: "pi_test_123_secret_abc")
        PaymentSheet.setSetupFutureUsage(for: .card, intentConfiguration: intentConfigWithPMOSFU, on: paymentIntentParams)
        XCTAssertEqual(STPFormEncoder.dictionary(forObject: paymentIntentParams)[jsonDict: "payment_method_options"]?[jsonDict: "card"]?["setup_future_usage"] as? String, "off_session")
        // ...and not SFU
        XCTAssertEqual(paymentIntentParams.setupFutureUsage, nil)

        // When PMO SFU is not set and SFU is set...
        let intentConfigWithTopLevelSFU = PaymentSheet.IntentConfiguration(
            mode: .payment(
                amount: 100,
                currency: "USD",
                setupFutureUsage: .onSession
            )
        ) { _, _ in return "" }

        // ...SFU should be set on the params
        let paymentIntentParams2 = STPPaymentIntentParams(clientSecret: "pi_test_456_secret_def")
        PaymentSheet.setSetupFutureUsage(for: .card, intentConfiguration: intentConfigWithTopLevelSFU, on: paymentIntentParams2)
        XCTAssertNil(STPFormEncoder.dictionary(forObject: paymentIntentParams2)[jsonDict: "payment_method_options"]?[jsonDict: "card"]?["setup_future_usage"])
        XCTAssertEqual(paymentIntentParams2.setupFutureUsage, .onSession)

        // When SFU and PMO SFU are both set...
        let intentConfigWithBoth = PaymentSheet.IntentConfiguration(
            mode: .payment(
                amount: 100,
                currency: "USD",
                setupFutureUsage: .offSession,  // This should be overridden by PMO SFU
                paymentMethodOptions: .init(setupFutureUsageValues: [.card: .none])
            )
        ) { _, _ in return "" }

        let paymentIntentParams3 = STPPaymentIntentParams(clientSecret: "pi_test_789_secret_ghi")
        PaymentSheet.setSetupFutureUsage(for: .card, intentConfiguration: intentConfigWithBoth, on: paymentIntentParams3)

        // ...both should be set to match
        XCTAssertEqual(STPFormEncoder.dictionary(forObject: paymentIntentParams3)[jsonDict: "payment_method_options"]?[jsonDict: "card"]?["setup_future_usage"] as? String, "none")
        XCTAssertEqual(paymentIntentParams3.setupFutureUsage, STPPaymentIntentSetupFutureUsage.offSession)
    }

    // MARK: - Shared Payment Token Session Tests

    func testHandleDeferredIntentConfirmation_withPreparePaymentMethodHandler_callsHandlerWithCorrectParameters() {
        // Given
        let testPaymentMethod = createValidSavedPaymentMethod()
        let handlerCalledExpectation = expectation(description: "PreparePaymentMethodHandler called")
        let completionCalledExpectation = expectation(description: "Completion called")

        var capturedPaymentMethod: STPPaymentMethod?
        var capturedShippingAddress: STPAddress?
        var capturedResult: PaymentSheetResult?
        var capturedDeferredType: STPAnalyticsClient.DeferredIntentConfirmationType?

        let preparePaymentMethodHandler: PaymentSheet.IntentConfiguration.PreparePaymentMethodHandler = { paymentMethod, shippingAddress in
            capturedPaymentMethod = paymentMethod
            capturedShippingAddress = shippingAddress
            handlerCalledExpectation.fulfill()
        }

        let sellerDetails = PaymentSheet.IntentConfiguration.SellerDetails(
            networkId: "test_network_id",
            externalId: "test_external_id",
            businessName: "Till's Pills"
        )

        let intentConfig = PaymentSheet.IntentConfiguration(
            sharedPaymentTokenSessionWithMode: .payment(amount: 1000, currency: "USD"),
            sellerDetails: sellerDetails,
            preparePaymentMethodHandler: preparePaymentMethodHandler
        )

        // When
        PaymentSheet.handleDeferredIntentConfirmation(
            confirmType: .saved(testPaymentMethod, paymentOptions: nil),
            configuration: configuration,
            intentConfig: intentConfig,
            authenticationContext: TestAuthenticationContext(),
            paymentHandler: STPPaymentHandler(apiClient: apiClient),
            isFlowController: false
        ) { result, deferredType in
            capturedResult = result
            capturedDeferredType = deferredType
            completionCalledExpectation.fulfill()
        }

        // Then
        wait(for: [handlerCalledExpectation, completionCalledExpectation], timeout: 5.0)

        XCTAssertNotNil(capturedPaymentMethod, "Payment method should be passed to handler")
        XCTAssertEqual(capturedPaymentMethod?.stripeId, testPaymentMethod.stripeId, "Correct payment method should be passed")

        // Verify shipping address is properly passed from configuration
        XCTAssertNotNil(capturedShippingAddress, "Shipping address should be passed from configuration")
        XCTAssertEqual(capturedShippingAddress?.name, "Jane Doe", "Shipping address name should match configuration")
        XCTAssertEqual(capturedShippingAddress?.phone, "5551234567", "Shipping address phone should match configuration")
        XCTAssertEqual(capturedShippingAddress?.country, "US", "Shipping address country should match configuration")
        XCTAssertEqual(capturedShippingAddress?.line1, "Line 1", "Shipping address line1 should match configuration")

        guard case .completed = capturedResult else {
            XCTFail("Result should be .completed")
            return
        }

        XCTAssertEqual(capturedDeferredType, .completeWithoutConfirmingIntent, "Should complete without confirming intent")
    }

    func testHandleDeferredIntentConfirmation_withPreparePaymentMethodHandler_newPaymentMethod() {
        // Given
        let handlerCalledExpectation = expectation(description: "PreparePaymentMethodHandler called")
        let completionCalledExpectation = expectation(description: "Completion called")

        var capturedPaymentMethod: STPPaymentMethod?
        var capturedResult: PaymentSheetResult?

        let preparePaymentMethodHandler: PaymentSheet.IntentConfiguration.PreparePaymentMethodHandler = { paymentMethod, _ in
            capturedPaymentMethod = paymentMethod
            handlerCalledExpectation.fulfill()
        }

        let intentConfig = PaymentSheet.IntentConfiguration(
            sharedPaymentTokenSessionWithMode: .payment(amount: 1000, currency: "USD"),
            sellerDetails: PaymentSheet.IntentConfiguration.SellerDetails(networkId: "test_network", externalId: "test_external", businessName: "Till's Pills"),
            preparePaymentMethodHandler: preparePaymentMethodHandler
        )

        let cardParams = STPPaymentMethodCardParams()
        cardParams.number = "4242424242424242"
        cardParams.cvc = "123"
        cardParams.expYear = 32
        cardParams.expMonth = 12

        let paymentMethodParams = STPPaymentMethodParams(
            card: cardParams,
            billingDetails: STPPaymentMethodBillingDetails(),
            metadata: nil
        )

        // When
        PaymentSheet.handleDeferredIntentConfirmation(
            confirmType: .new(
                params: paymentMethodParams,
                paymentOptions: .init(),
                paymentMethod: nil,
                shouldSave: false,
                shouldSetAsDefaultPM: false
            ),
            configuration: configuration,
            intentConfig: intentConfig,
            authenticationContext: TestAuthenticationContext(),
            paymentHandler: STPPaymentHandler(apiClient: apiClient),
            isFlowController: false
        ) { result, _ in
            capturedResult = result
            completionCalledExpectation.fulfill()
        }

        // Then
        wait(for: [handlerCalledExpectation, completionCalledExpectation], timeout: 10.0)

        XCTAssertNotNil(capturedPaymentMethod, "Payment method should be created and passed to handler")
        XCTAssertEqual(capturedPaymentMethod?.type, .card, "Payment method should be of type card")

        guard case .completed = capturedResult else {
            XCTFail("Result should be .completed")
            return
        }
    }

    func testHandleDeferredIntentConfirmation_withPreparePaymentMethodHandler_setupMode() {
        // Given
        let testPaymentMethod = createValidSavedPaymentMethod()
        let handlerCalledExpectation = expectation(description: "PreparePaymentMethodHandler called")
        let completionCalledExpectation = expectation(description: "Completion called")

        var capturedResult: PaymentSheetResult?

        let preparePaymentMethodHandler: PaymentSheet.IntentConfiguration.PreparePaymentMethodHandler = { _, _ in
            handlerCalledExpectation.fulfill()
        }

        let intentConfig = PaymentSheet.IntentConfiguration(
            sharedPaymentTokenSessionWithMode: .setup(currency: "USD"),
            sellerDetails: PaymentSheet.IntentConfiguration.SellerDetails(networkId: "test_network", externalId: "test_external", businessName: "Till's Pills"),
            preparePaymentMethodHandler: preparePaymentMethodHandler
        )

        // When
        PaymentSheet.handleDeferredIntentConfirmation(
            confirmType: .saved(testPaymentMethod, paymentOptions: nil),
            configuration: configuration,
            intentConfig: intentConfig,
            authenticationContext: TestAuthenticationContext(),
            paymentHandler: STPPaymentHandler(apiClient: apiClient),
            isFlowController: false
        ) { result, _ in
            capturedResult = result
            completionCalledExpectation.fulfill()
        }

        // Then
        wait(for: [handlerCalledExpectation, completionCalledExpectation], timeout: 5.0)

        guard case .completed = capturedResult else {
            XCTFail("Result should be .completed")
            return
        }
    }

    func testHandleDeferredIntentConfirmation_withoutPreparePaymentMethodHandler_proceedsToNormalFlow() {
        // Given
        let testPaymentMethod = createValidSavedPaymentMethod()
        let completionCalledExpectation = expectation(description: "Completion called")

        var capturedResult: PaymentSheetResult?
        var capturedDeferredType: STPAnalyticsClient.DeferredIntentConfirmationType?

        let confirmHandler: PaymentSheet.IntentConfiguration.ConfirmHandler = { _, _, intentCreationCallback in
            // Return a client secret to simulate normal flow
            STPTestingAPIClient.shared.fetchPaymentIntent(types: ["card"]) { result in
                switch result {
                case .success(let clientSecret):
                    intentCreationCallback(.success(clientSecret))
                case .failure(let error):
                    intentCreationCallback(.failure(error))
                }
            }
        }

        let intentConfig = PaymentSheet.IntentConfiguration(
            mode: .payment(amount: 1000, currency: "USD"),
            confirmHandler: confirmHandler
        )

        // When
        PaymentSheet.handleDeferredIntentConfirmation(
            confirmType: .saved(testPaymentMethod, paymentOptions: nil),
            configuration: configuration,
            intentConfig: intentConfig,
            authenticationContext: TestAuthenticationContext(),
            paymentHandler: STPPaymentHandler(apiClient: apiClient),
            isFlowController: false
        ) { result, deferredType in
            capturedResult = result
            capturedDeferredType = deferredType
            completionCalledExpectation.fulfill()
        }

        // Then
        wait(for: [completionCalledExpectation], timeout: 10.0)

        // Should proceed to normal confirmation flow, not early return
        XCTAssertNotEqual(capturedDeferredType, .completeWithoutConfirmingIntent, "Should not complete immediately without confirming intent")

        // The result could be completed or failed depending on the network request, but it should not be the immediate completion
        XCTAssertNotNil(capturedResult, "Result should be set")
    }

    func testHandleDeferredIntentConfirmation_withPreparePaymentMethodHandler_doesNotProceedToIntentConfirmation() {
        // Given
        let testPaymentMethod = createValidSavedPaymentMethod()
        let handlerCalledExpectation = expectation(description: "PreparePaymentMethodHandler called")
        let completionCalledExpectation = expectation(description: "Completion called")

        var intentCreationCallbackInvoked = false

        let preparePaymentMethodHandler: PaymentSheet.IntentConfiguration.PreparePaymentMethodHandler = { _, _ in
            handlerCalledExpectation.fulfill()
        }

        var intentConfig = PaymentSheet.IntentConfiguration(
            sharedPaymentTokenSessionWithMode: .payment(amount: 1000, currency: "USD"),
            sellerDetails: PaymentSheet.IntentConfiguration.SellerDetails(networkId: "test_network", externalId: "test_external", businessName: "Till's Pills"),
            preparePaymentMethodHandler: preparePaymentMethodHandler
        )

        // Override the confirmHandler to detect if it's called (it shouldn't be)
        let originalConfirmHandler = intentConfig.confirmHandler
        intentConfig.confirmHandler = { paymentMethod, shouldSave, callback in
            intentCreationCallbackInvoked = true
            originalConfirmHandler(paymentMethod, shouldSave, callback)
        }

        // When
        PaymentSheet.handleDeferredIntentConfirmation(
            confirmType: .saved(testPaymentMethod, paymentOptions: nil),
            configuration: configuration,
            intentConfig: intentConfig,
            authenticationContext: TestAuthenticationContext(),
            paymentHandler: STPPaymentHandler(apiClient: apiClient),
            isFlowController: false
        ) { _, _ in
            completionCalledExpectation.fulfill()
        }

        // Then
        wait(for: [handlerCalledExpectation, completionCalledExpectation], timeout: 5.0)

        XCTAssertFalse(intentCreationCallbackInvoked, "Intent creation callback should not be invoked when using preparePaymentMethodHandler")
    }
}

// MARK: - Test Helper Classes

private class TestAuthenticationContext: NSObject, STPAuthenticationContext {
    func authenticationPresentingViewController() -> UIViewController {
        return UIViewController()
    }
}
