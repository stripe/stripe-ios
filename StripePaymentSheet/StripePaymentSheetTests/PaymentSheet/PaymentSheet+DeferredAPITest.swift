//
//  PaymentSheet+DeferredAPITest.swift
//  StripePaymentSheetTests
//
//  Created by Nick Porter on 10/11/23.
//

@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripeCoreTestUtils
@testable@_spi(STP) import StripePayments
@testable@_spi(STP) @_spi(SharedPaymentToken) import StripePaymentSheet
@testable@_spi(STP) import StripePaymentsTestUtils
@testable@_spi(STP) import StripeUICore
import XCTest

final class PaymentSheet_DeferredAPITest: XCTestCase {
    let apiClient = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)

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
            externalId: "test_external_id"
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

        let preparePaymentMethodHandler: PaymentSheet.IntentConfiguration.PreparePaymentMethodHandler = { paymentMethod, shippingAddress in
            capturedPaymentMethod = paymentMethod
            handlerCalledExpectation.fulfill()
        }

        let intentConfig = PaymentSheet.IntentConfiguration(
            sharedPaymentTokenSessionWithMode: .payment(amount: 1000, currency: "USD"),
            sellerDetails: PaymentSheet.IntentConfiguration.SellerDetails(networkId: "test_network", externalId: "test_external"),
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
            sellerDetails: PaymentSheet.IntentConfiguration.SellerDetails(networkId: "test_network", externalId: "test_external"),
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
            sellerDetails: PaymentSheet.IntentConfiguration.SellerDetails(networkId: "test_network", externalId: "test_external"),     
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
        ) { result, _ in
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
