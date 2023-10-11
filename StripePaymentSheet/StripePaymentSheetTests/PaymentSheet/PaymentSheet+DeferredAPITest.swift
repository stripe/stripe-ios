//
//  PaymentSheet+DeferredAPITest.swift
//  StripePaymentSheetTests
//
//  Created by Nick Porter on 10/11/23.
//

@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripeCoreTestUtils
@testable@_spi(STP) import StripePayments
@testable@_spi(STP) import StripePaymentSheet
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

    lazy var paymentHandler: STPPaymentHandler = {
        return STPPaymentHandler(
            apiClient: apiClient,
            formSpecPaymentHandler: PaymentSheetFormSpecPaymentHandler()
        )
    }()

    var confirmHandlerPaymentIntent: PaymentSheet.IntentConfiguration.ConfirmHandler = { _, _, intentCreationCallback in
        let createIntentCompletion: (String?, Error?) -> Void = { clientSecret, error in
            if let clientSecret {
                intentCreationCallback(.success(clientSecret))
            } else {
                intentCreationCallback(.failure(error ?? ExpectedError()))
            }
        }
        let params: [String: Any] = [
            "amount": 1050,
        ]
        STPTestingAPIClient.shared.createPaymentIntent(withParams: params, completion: createIntentCompletion)
    }

    var confirmHandlerSetupIntent: PaymentSheet.IntentConfiguration.ConfirmHandler = { _, _, intentCreationCallback in
        let createIntentCompletion: (String?, Error?) -> Void = { clientSecret, error in
            if let clientSecret {
                intentCreationCallback(.success(clientSecret))
            } else {
                intentCreationCallback(.failure(error ?? ExpectedError()))
            }
        }

        STPTestingAPIClient.shared.createSetupIntent(withParams: [:], completion: createIntentCompletion)
    }

    struct ExpectedError: LocalizedError {
        var errorDescription: String?
    }

    // MARK: handleDeferredIntentConfirmation Dashboard tests

    // When isDashboardApp is true for a PaymentIntent we should call the Dashboard closure
    func testHandleDeferredIntentConfirmation_shouldCallDashboardClosure_paymentIntent() {
        let expectation = XCTestExpectation()
        let intentConfig = PaymentSheet.IntentConfiguration(mode: .payment(amount: 1050, currency: "USD"), confirmHandler: confirmHandlerPaymentIntent)

        PaymentSheet.handleDeferredIntentConfirmation(confirmType: .saved(createValidSavedPaymentMethod()),
                                                      configuration: configuration, intentConfig: intentConfig, authenticationContext: self, paymentHandler: paymentHandler, isFlowController: false, isDashboardApp: true) { _, _, _, _ in
            expectation.fulfill()
            return STPPaymentIntentParams()
        } completion: { _, _ in
            // no-op
        }

        wait(for: [expectation], timeout: 5.0)
    }

    // When isDashboardApp for a PaymentIntent is false we should not call the Dashboard closure
    func testHandleDeferredIntentConfirmation_shouldNotCallDashboardClosure_paymentIntent() {
        let expectation = XCTestExpectation()
        expectation.isInverted = true
        let intentConfig = PaymentSheet.IntentConfiguration(mode: .payment(amount: 1050, currency: "USD"), confirmHandler: confirmHandlerPaymentIntent)

        PaymentSheet.handleDeferredIntentConfirmation(confirmType: .saved(createValidSavedPaymentMethod()),
                                                      configuration: configuration, intentConfig: intentConfig, authenticationContext: self, paymentHandler: paymentHandler, isFlowController: false, isDashboardApp: false) { _, _, _, _ in
            expectation.fulfill()
            return STPPaymentIntentParams()
        } completion: { _, _ in
            // no-op
        }

        wait(for: [expectation], timeout: 5.0)
    }

    // When isDashboardApp is true for a SetupIntent we should not call the Dashboard closure
    func testHandleDeferredIntentConfirmation_shouldCallDashboardClosure_setupIntent() {
        let expectation = XCTestExpectation()
        expectation.isInverted = true
        let intentConfig = PaymentSheet.IntentConfiguration(mode: .setup(currency: "USD", setupFutureUsage: .offSession), confirmHandler: confirmHandlerSetupIntent)

        PaymentSheet.handleDeferredIntentConfirmation(confirmType: .saved(createValidSavedPaymentMethod()),
                                                      configuration: configuration, intentConfig: intentConfig, authenticationContext: self, paymentHandler: paymentHandler, isFlowController: false, isDashboardApp: true) { _, _, _, _ in
            expectation.fulfill()
            return STPPaymentIntentParams()
        } completion: { _, _ in
            // no-op
        }

        wait(for: [expectation], timeout: 5.0)
    }

    // When isDashboardApp for a SetupIntent is false we should not call the Dashboard closure
    func testHandleDeferredIntentConfirmation_shouldNotCallDashboardClosure_setupIntent() {
        let expectation = XCTestExpectation()
        expectation.isInverted = true
        let intentConfig = PaymentSheet.IntentConfiguration(mode: .setup(currency: "USD", setupFutureUsage: .offSession), confirmHandler: confirmHandlerSetupIntent)

        PaymentSheet.handleDeferredIntentConfirmation(confirmType: .saved(createValidSavedPaymentMethod()),
                                                      configuration: configuration, intentConfig: intentConfig, authenticationContext: self, paymentHandler: paymentHandler, isFlowController: false, isDashboardApp: false) { _, _, _, _ in
            expectation.fulfill()
            return STPPaymentIntentParams()
        } completion: { _, _ in
            // no-op
        }

        wait(for: [expectation], timeout: 5.0)
    }

    // MARK: setParamsForDashboardApp tests
    func testSetParamsForDashboardApp_saved() {
        let examplePaymentMethodParams = STPPaymentMethodParams(card: STPFixtures.paymentMethodCardParams(), billingDetails: nil, metadata: nil)
        let paymentOptions = STPConfirmPaymentMethodOptions()
        let examplePaymentMethod = STPFixtures.paymentMethod()
        var configurationWithCustomer = configuration
        configurationWithCustomer.customer = .init(id: "id", ephemeralKeySecret: "ek")
        let params = PaymentSheet.setParamsForDashboardApp(confirmType: .new(params: examplePaymentMethodParams,
                                                                             paymentOptions: paymentOptions,
                                                                             paymentMethod: examplePaymentMethod,
                                                                             shouldSave: true),
                                                           paymentIntentParams: .init(),
                                                           paymentIntent: STPFixtures.makePaymentIntent(),
                                                           configuration: configurationWithCustomer)

        // moto should be set to true and sfu = off_session
        XCTAssertTrue(params.paymentMethodOptions?.cardOptions?.additionalAPIParameters["moto"] as? Bool ?? false)
        XCTAssertEqual(params.paymentMethodOptions?.cardOptions?.additionalAPIParameters["setup_future_usage"] as? String, "off_session")
    }

    func testSetParamsForDashboardApp_new() {
        let params = PaymentSheet.setParamsForDashboardApp(confirmType: .saved(createValidSavedPaymentMethod()),
                                                           paymentIntentParams: .init(),
                                                           paymentIntent: STPFixtures.makePaymentIntent(),
                                                           configuration: configuration)

        // moto should be set to true
        XCTAssertTrue(params.paymentMethodOptions?.cardOptions?.additionalAPIParameters["moto"] as? Bool ?? false)
    }

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
}

// MARK: - STPAuthenticationContext

extension PaymentSheet_DeferredAPITest: STPAuthenticationContext {
    func authenticationPresentingViewController() -> UIViewController {
        return UIViewController()
    }
}
