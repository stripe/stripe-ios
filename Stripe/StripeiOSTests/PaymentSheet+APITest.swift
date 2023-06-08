//
//  PaymentSheet+APITest.swift
//  StripeiOS Tests
//
//  Created by Jaime Park on 6/29/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import StripeCoreTestUtils
import XCTest

@testable@_spi(STP) import Stripe
@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePayments
@testable@_spi(STP) @_spi(ExperimentalPaymentSheetDecouplingAPI) import StripePaymentSheet

class PaymentSheetAPITest: XCTestCase {

    let apiClient = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)
    lazy var paymentHandler: STPPaymentHandler = {
        return STPPaymentHandler(
            apiClient: apiClient,
            formSpecPaymentHandler: PaymentSheetFormSpecPaymentHandler()
        )
    }()
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

    lazy var newCardPaymentOption: PaymentSheet.PaymentOption = {
        let cardParams = STPPaymentMethodCardParams()
        cardParams.number = "4242424242424242"
        cardParams.cvc = "123"
        cardParams.expYear = 32
        cardParams.expMonth = 12
        let newCardPaymentOption: PaymentSheet.PaymentOption = .new(
            confirmParams: .init(
                params: .init(
                    card: cardParams,
                    billingDetails: .init(),
                    metadata: nil
                ),
                type: .card
            )
        )

        return newCardPaymentOption
    }()

    override class func setUp() {
        super.setUp()
        // `PaymentSheet.load()` uses the `LinkAccountService` to lookup the Link user account.
        // Override the default cookie store since Keychain is not available in this test case.
        LinkAccountService.defaultCookieStore = LinkInMemoryCookieStore()
    }

    // MARK: - load and confirm tests

    func testPaymentSheetLoadAndConfirmWithPaymentIntent() {
        let expectation = XCTestExpectation(description: "Retrieve Payment Intent With Preferences")
        let types = ["ideal", "card", "bancontact", "sofort"]
        let expected = [.card, .iDEAL, .bancontact, .sofort]
            .filter { PaymentSheet.supportedPaymentMethods.contains($0) }

        // 0. Create a PI on our test backend
        fetchPaymentIntent(types: types) { result in
            switch result {
            case .success(let clientSecret):
                // 1. Load the PI
                PaymentSheet.load(
                    mode: .paymentIntentClientSecret(clientSecret),
                    configuration: self.configuration
                ) { result in
                    switch result {
                    case .success(let paymentIntent, let paymentMethods, _):
                        XCTAssertEqual(
                            Set(paymentIntent.recommendedPaymentMethodTypes),
                            Set(expected)
                        )
                        XCTAssertEqual(paymentMethods, [])
                        // 2. Confirm the intent with a new card

                        PaymentSheet.confirm(
                            configuration: self.configuration,
                            authenticationContext: self,
                            intent: paymentIntent,
                            paymentOption: self.newCardPaymentOption,
                            paymentHandler: self.paymentHandler
                        ) { result in
                            switch result {
                            case .completed:
                                // 3. Fetch the PI
                                self.apiClient.retrievePaymentIntent(withClientSecret: clientSecret)
                                { paymentIntent, _ in
                                    // Make sure the PI is succeeded and contains shipping
                                    XCTAssertNotNil(paymentIntent?.shipping)
                                    XCTAssertEqual(
                                        paymentIntent?.shipping?.name,
                                        self.configuration.shippingDetails()?.name
                                    )
                                    XCTAssertEqual(
                                        paymentIntent?.shipping?.phone,
                                        self.configuration.shippingDetails()?.phone
                                    )
                                    XCTAssertEqual(
                                        paymentIntent?.shipping?.address?.line1,
                                        self.configuration.shippingDetails()?.address.line1
                                    )
                                    XCTAssertEqual(paymentIntent?.status, .succeeded)
                                }
                            case .canceled:
                                XCTFail("Confirm canceled")
                            case .failed(let error):
                                XCTFail("Failed to confirm: \(error)")
                            }
                            expectation.fulfill()
                        }
                    case .failure(let error):
                        print(error)
                    }
                }

            case .failure(let error):
                print(error)
            }
        }
        wait(for: [expectation], timeout: STPTestingNetworkRequestTimeout)
    }

    func testPaymentSheetLoadWithSetupIntent() {
        let expectation = XCTestExpectation(description: "Retrieve Setup Intent With Preferences")
        let types = ["ideal", "card", "bancontact", "sofort"]
        let expected: [STPPaymentMethodType] = [.card, .iDEAL, .bancontact, .sofort]
        fetchSetupIntent(types: types) { result in
            switch result {
            case .success(let clientSecret):
                PaymentSheet.load(
                    mode: .setupIntentClientSecret(clientSecret),
                    configuration: self.configuration
                ) { result in
                    switch result {
                    case .success(let setupIntent, let paymentMethods, _):
                        XCTAssertEqual(
                            Set(setupIntent.recommendedPaymentMethodTypes),
                            Set(expected)
                        )
                        XCTAssertEqual(paymentMethods, [])
                        expectation.fulfill()
                    case .failure(let error):
                        print(error)
                    }
                }

            case .failure(let error):
                print(error)
            }
        }
        wait(for: [expectation], timeout: STPTestingNetworkRequestTimeout)
    }

    func testPaymentSheetLoadDeferredIntentSucceeds() {
        let loadExpectation = XCTestExpectation(description: "Load PaymentSheet")
        // Test PaymentSheet.load can load various IntentConfigurations
        let confirmHandler: PaymentSheet.IntentConfiguration.ConfirmHandler = {_, _, _ in
            XCTFail("Confirm handler shouldn't be called.")
        }
        let intentConfigTestcases: [PaymentSheet.IntentConfiguration] = [
            // Typical auto pm payment config
            .init(mode: .payment(amount: 1000, currency: "USD"), confirmHandler: confirmHandler),
            // Payment config with explicit PM types
            .init(mode: .payment(amount: 1000, currency: "USD"), paymentMethodTypes: ["card"], confirmHandler: confirmHandler),
            // Typical auto pm setup config
            .init(mode: .setup(currency: "USD"), confirmHandler: confirmHandler),
            // Setup config with explicit PM types
            .init(mode: .setup(currency: "USD"), paymentMethodTypes: ["card"], confirmHandler: confirmHandler),
            // Setup config w/o currency
            .init(mode: .setup(), confirmHandler: confirmHandler),
        ]
        loadExpectation.expectedFulfillmentCount = intentConfigTestcases.count
        for (index, intentConfig) in intentConfigTestcases.enumerated() {
            PaymentSheet.load(mode: .deferredIntent(intentConfig), configuration: self.configuration) { result in
                loadExpectation.fulfill()
                switch result {
                case .success(let intent, _, _):
                    guard case .deferredIntent = intent else {
                        XCTFail()
                        return
                    }
                case .failure(let error):
                    XCTFail("Test case at index \(index) failed: \(error)")
                    print(error)
                }
            }
        }
        wait(for: [loadExpectation], timeout: STPTestingNetworkRequestTimeout)
    }

    func testPaymentSheetLoadDeferredIntentFails() {
        let loadExpectation = XCTestExpectation(description: "Load PaymentSheet")
        // Test PaymentSheet.load can load various IntentConfigurations
        let confirmHandler: PaymentSheet.IntentConfiguration.ConfirmHandler = {_, _, _ in
            XCTFail("Confirm handler shouldn't be called.")
        }
        let intentConfigTestcases: [PaymentSheet.IntentConfiguration] = [
            // Bad currency
            .init(mode: .payment(amount: 1000, currency: "FOO"), confirmHandler: confirmHandler),
            // Bad amount
            .init(mode: .payment(amount: 0, currency: "USD"), paymentMethodTypes: ["card"], confirmHandler: confirmHandler),
            // Bad pm type
            .init(mode: .setup(currency: "USD"), paymentMethodTypes: ["card", "foo"], confirmHandler: confirmHandler),
            // Bad OBO
            .init(mode: .setup(currency: "USD"), paymentMethodTypes: ["card"], onBehalfOf: "foo", confirmHandler: confirmHandler),
        ]
        loadExpectation.expectedFulfillmentCount = intentConfigTestcases.count
        for (index, intentConfig) in intentConfigTestcases.enumerated() {
            PaymentSheet.load(mode: .deferredIntent(intentConfig), configuration: self.configuration) { result in
                loadExpectation.fulfill()
                switch result {
                case .success:
                    XCTFail("Test case at index \(index) succeeded to load but it should have failed.")
                case .failure:
                    break
                }
            }
        }
        wait(for: [loadExpectation], timeout: STPTestingNetworkRequestTimeout)
    }

    func testPaymentSheetLoadAndConfirmWithDeferredIntent() {
        let loadExpectation = XCTestExpectation(description: "Load PaymentSheet")
        let confirmExpectation = XCTestExpectation(description: "Confirm deferred intent")
        let callbackExpectation = XCTestExpectation(description: "Confirm callback invoked")

        let types = ["card", "cashapp"]
        let expected: [STPPaymentMethodType] = [.card, .cashApp]
        let confirmHandler: PaymentSheet.IntentConfiguration.ConfirmHandler = {_, _, intentCreationCallback in
            self.fetchPaymentIntent(types: types, currency: "USD") { result in
                switch result {
                case .success(let clientSecret):
                    intentCreationCallback(.success(clientSecret))
                    callbackExpectation.fulfill()
                case .failure(let error):
                    print(error)
                }
            }
        }
        let intentConfig = PaymentSheet.IntentConfiguration(mode: .payment(amount: 1050, currency: "USD"),
                                                            paymentMethodTypes: types,
                                                            confirmHandler: confirmHandler)
        PaymentSheet.load(
            mode: .deferredIntent(intentConfig),
            configuration: self.configuration
        ) { result in
            switch result {
            case .success(let intent, let paymentMethods, _):
                XCTAssertEqual(
                    Set(intent.recommendedPaymentMethodTypes),
                    Set(expected)
                )
                XCTAssertEqual(paymentMethods, [])
                loadExpectation.fulfill()
                guard case .deferredIntent(elementsSession: let elementsSession, intentConfig: _) = intent else {
                    XCTFail()
                    return
                }

                PaymentSheet.confirm(configuration: self.configuration,
                                     authenticationContext: self,
                                     intent: .deferredIntent(elementsSession: elementsSession,
                                                             intentConfig: intentConfig),
                                     paymentOption: self.newCardPaymentOption,
                                     paymentHandler: self.paymentHandler) { result in
                    switch result {
                    case .completed:
                        confirmExpectation.fulfill()
                    case .canceled:
                        XCTFail("Confirm canceled")
                    case .failed(let error):
                        XCTFail("Failed to confirm: \(error)")
                    }
                }

            case .failure(let error):
                print(error)
            }
        }

        wait(for: [loadExpectation, confirmExpectation, callbackExpectation], timeout: STPTestingNetworkRequestTimeout)
    }

    func testPaymentSheetLoadAndConfirmWithDeferredIntent_serverSideConfirmation() {
        let loadExpectation = XCTestExpectation(description: "Load PaymentSheet")
        let confirmExpectation = XCTestExpectation(description: "Confirm deferred intent")
        let callbackExpectation = XCTestExpectation(description: "Confirm callback invoked")

        let types = ["card", "cashapp"]
        let expected: [STPPaymentMethodType] = [.card, .cashApp]
        let serverSideConfirmHandler: PaymentSheet.IntentConfiguration.ConfirmHandler = {paymentMethod, _, intentCreationCallback in
            self.fetchPaymentIntent(types: types,
                                    currency: "USD",
                                    paymentMethodID: paymentMethod.stripeId,
                                    confirm: true) { result in
                switch result {
                case .success(let clientSecret):
                    intentCreationCallback(.success(clientSecret))
                    callbackExpectation.fulfill()
                case .failure(let error):
                    print(error)
                }
            }
        }
        let intentConfig = PaymentSheet.IntentConfiguration(mode: .payment(amount: 1050, currency: "USD"),
                                                            paymentMethodTypes: types,
                                                            confirmHandler: serverSideConfirmHandler)
        PaymentSheet.load(
            mode: .deferredIntent(intentConfig),
            configuration: self.configuration
        ) { result in
            switch result {
            case .success(let intent, let paymentMethods, _):
                XCTAssertEqual(
                    Set(intent.recommendedPaymentMethodTypes),
                    Set(expected)
                )
                XCTAssertEqual(paymentMethods, [])
                loadExpectation.fulfill()
                guard case .deferredIntent(elementsSession: let elementsSession, intentConfig: _) = intent else {
                    XCTFail()
                    return
                }

                PaymentSheet.confirm(configuration: self.configuration,
                                     authenticationContext: self,
                                     intent: .deferredIntent(elementsSession: elementsSession,
                                                             intentConfig: intentConfig),
                                     paymentOption: self.newCardPaymentOption,
                                     paymentHandler: self.paymentHandler) { result in
                    switch result {
                    case .completed:
                        confirmExpectation.fulfill()
                    case .canceled:
                        XCTFail("Confirm canceled")
                    case .failed(let error):
                        XCTFail("Failed to confirm: \(error)")
                    }
                }

            case .failure(let error):
                print(error)
            }
        }

        wait(for: [loadExpectation, confirmExpectation, callbackExpectation], timeout: STPTestingNetworkRequestTimeout)
    }

    func testPaymentSheetLoadAndConfirmWithPaymentIntentAttachedPaymentMethod() {
        let expectation = XCTestExpectation(
            description: "Load PaymentIntent with an attached payment method"
        )
        // 0. Create a PI on our test backend with an already attached pm
        STPTestingAPIClient.shared().createPaymentIntent(withParams: [
            "amount": 1050,
            "payment_method": "pm_card_visa",
        ]) { clientSecret, error in
            guard let clientSecret = clientSecret, error == nil else {
                XCTFail()
                return
            }

            // 1. Load the PI
            PaymentSheet.load(
                mode: .paymentIntentClientSecret(clientSecret),
                configuration: self.configuration
            ) { result in
                guard case .success(let paymentIntent, _, _) = result else {
                    XCTFail()
                    return
                }
                // 2. Confirm with saved card
                PaymentSheet.confirm(
                    configuration: self.configuration,
                    authenticationContext: self,
                    intent: paymentIntent,
                    paymentOption: .saved(paymentMethod: .init(stripeId: "pm_card_visa")),
                    paymentHandler: self.paymentHandler
                ) { result in
                    switch result {
                    case .completed:
                        // 3. Fetch the PI
                        self.apiClient.retrievePaymentIntent(withClientSecret: clientSecret) {
                            paymentIntent,
                            _ in
                            // Make sure the PI is succeeded and contains shipping
                            XCTAssertNotNil(paymentIntent?.shipping)
                            XCTAssertEqual(
                                paymentIntent?.shipping?.name,
                                self.configuration.shippingDetails()?.name
                            )
                            XCTAssertEqual(
                                paymentIntent?.shipping?.phone,
                                self.configuration.shippingDetails()?.phone
                            )
                            XCTAssertEqual(
                                paymentIntent?.shipping?.address?.line1,
                                self.configuration.shippingDetails()?.address.line1
                            )
                            XCTAssertEqual(paymentIntent?.status, .succeeded)
                            expectation.fulfill()
                        }
                    case .canceled:
                        XCTFail("Confirm canceled")
                    case .failed(let error):
                        XCTFail("Failed to confirm: \(error)")
                    }
                }
            }
        }
        wait(for: [expectation], timeout: STPTestingNetworkRequestTimeout)
    }

    func testPaymentSheetLoadWithSetupIntentAttachedPaymentMethod() {
        let expectation = XCTestExpectation(
            description: "Load SetupIntent with an attached payment method"
        )
        STPTestingAPIClient.shared().createSetupIntent(withParams: [
            "payment_method": "pm_card_visa",
        ]) { clientSecret, error in
            guard let clientSecret = clientSecret, error == nil else {
                XCTFail()
                expectation.fulfill()
                return
            }

            PaymentSheet.load(
                mode: .setupIntentClientSecret(clientSecret),
                configuration: self.configuration
            ) { result in
                defer { expectation.fulfill() }
                guard case .success = result else {
                    XCTFail()
                    return
                }
            }
        }
        wait(for: [expectation], timeout: STPTestingNetworkRequestTimeout)
    }

    // MARK: - Deferred confirm tests
    struct TestCase {
        let name: String
        let isPaymentIntent: Bool
        let input_paymentOption: PaymentOption
        let expected_shouldSavePaymentMethod: Bool
        let expected_result: PaymentSheetResult
    }
    struct ExpectedError: LocalizedError {
        var errorDescription: String?
    }
    var valid_card_checkbox_selected: IntentConfirmParams {
        let intentConfirmParams = IntentConfirmParams(params: ._testValidCardValue(), type: .card)
        intentConfirmParams.saveForFutureUseCheckboxState = .selected
        return intentConfirmParams
    }
    var valid_card_checkbox_deselected: IntentConfirmParams {
        let intentConfirmParams = IntentConfirmParams(params: ._testValidCardValue(), type: .card)
        intentConfirmParams.saveForFutureUseCheckboxState = .deselected
        return intentConfirmParams
    }
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

    func testDeferredConfirm_valid_new_card_and_save_checkbox_selected() {
        _testDeferredConfirm(
            inputPaymentOption: .new(confirmParams: valid_card_checkbox_selected),
            expectedShouldSavePaymentMethod: true,
            expectedResult: .completed,
            isPaymentIntent: true,
            isServerSideConfirm: false // Client-side confirmation

        )
        _testDeferredConfirm(
            inputPaymentOption: .new(confirmParams: valid_card_checkbox_selected),
            expectedShouldSavePaymentMethod: true,
            expectedResult: .completed,
            isPaymentIntent: true,
            isServerSideConfirm: true // Server-side confirmation
        )
    }

    func testDeferredConfirm_valid_new_card_and_save_checkbox_deselected() {
        _testDeferredConfirm(
            inputPaymentOption: .new(confirmParams: valid_card_checkbox_deselected),
            expectedShouldSavePaymentMethod: false,
            expectedResult: .completed,
            isPaymentIntent: true, // PaymentIntent
            isServerSideConfirm: false // Client-side confirmation
        )
        _testDeferredConfirm(
            inputPaymentOption: .new(confirmParams: valid_card_checkbox_deselected),
            expectedShouldSavePaymentMethod: false,
            expectedResult: .completed,
            isPaymentIntent: true, // PaymentIntent
            isServerSideConfirm: true // Server-side confirmation
        )
    }

    func testDeferredConfirm_valid_saved_card() {
        _testDeferredConfirm(
            inputPaymentOption: .saved(paymentMethod: createValidSavedPaymentMethod()),
            expectedShouldSavePaymentMethod: false,
            expectedResult: .completed,
            isPaymentIntent: true, // PaymentIntent
            isServerSideConfirm: false // Client-side confirmation
        )
        _testDeferredConfirm(
            inputPaymentOption: .saved(paymentMethod: createValidSavedPaymentMethod()),
            expectedShouldSavePaymentMethod: false,
            expectedResult: .completed,
            isPaymentIntent: true, // PaymentIntent
            isServerSideConfirm: true // Server-side confirmation
        )
        _testDeferredConfirm(
            inputPaymentOption: .saved(paymentMethod: createValidSavedPaymentMethod()),
            expectedShouldSavePaymentMethod: false,
            expectedResult: .completed,
            isPaymentIntent: false, // SetupIntent
            isServerSideConfirm: false // Client-side confirmation
        )
        _testDeferredConfirm(
            inputPaymentOption: .saved(paymentMethod: createValidSavedPaymentMethod()),
            expectedShouldSavePaymentMethod: false,
            expectedResult: .completed,
            isPaymentIntent: false, // SetupIntent
            isServerSideConfirm: true // Server-side confirmation
        )
    }

    func testDeferredConfirm_new_expired_card() {
        // Note: This fails when the PM is created
        let invalid_exp_year_card = IntentConfirmParams(params: .init(card: STPFixtures.paymentMethodCardParams(), billingDetails: nil, metadata: nil), type: .card)
        _testDeferredConfirm(
            inputPaymentOption: .new(confirmParams: invalid_exp_year_card),
            expectedShouldSavePaymentMethod: false,
            expectedResult: .failed(error: ExpectedError(errorDescription: "Your card's expiration year is invalid.")),
            isPaymentIntent: true, // PaymentIntent
            isServerSideConfirm: false // Client-side confirmation
        )
        _testDeferredConfirm(
            inputPaymentOption: .new(confirmParams: invalid_exp_year_card),
            expectedShouldSavePaymentMethod: false,
            expectedResult: .failed(error: ExpectedError(errorDescription: "Your card's expiration year is invalid.")),
            isPaymentIntent: true, // PaymentIntent
            isServerSideConfirm: true // Server-side confirmation
        )
        _testDeferredConfirm(
            inputPaymentOption: .new(confirmParams: invalid_exp_year_card),
            expectedShouldSavePaymentMethod: false,
            expectedResult: .failed(error: ExpectedError(errorDescription: "Your card's expiration year is invalid.")),
            isPaymentIntent: false, // SetupIntent
            isServerSideConfirm: false // Client-side confirmation
        )
        _testDeferredConfirm(
            inputPaymentOption: .new(confirmParams: invalid_exp_year_card),
            expectedShouldSavePaymentMethod: false,
            expectedResult: .failed(error: ExpectedError(errorDescription: "Your card's expiration year is invalid.")),
            isPaymentIntent: false, // SetupIntent
            isServerSideConfirm: true // Server-side confirmation
        )
    }

    func testDeferredConfirm_new_insufficient_funds_card() {
        // Note: This fails when the intent is confirmed
        let insufficient_funds_new_PM = IntentConfirmParams(params: ._testCardValue(number: "4000000000009995"), type: .card)
        _testDeferredConfirm(
            inputPaymentOption: .new(confirmParams: insufficient_funds_new_PM),
            expectedShouldSavePaymentMethod: false,
            expectedResult: .failed(error: ExpectedError(errorDescription: "Your card has insufficient funds.")),
            isPaymentIntent: true, // PaymentIntent
            isServerSideConfirm: false // Client-side confirmation
        )
        _testDeferredConfirm(
            inputPaymentOption: .new(confirmParams: insufficient_funds_new_PM),
            expectedShouldSavePaymentMethod: false,
            expectedResult: .failed(error: ExpectedError(errorDescription: "Your card has insufficient funds.")),
            isPaymentIntent: true, // PaymentIntent
            isServerSideConfirm: true // Server-side confirmation
        )
        _testDeferredConfirm(
            inputPaymentOption: .new(confirmParams: insufficient_funds_new_PM),
            expectedShouldSavePaymentMethod: false,
            expectedResult: .failed(error: ExpectedError(errorDescription: "Your card has insufficient funds.")),
            isPaymentIntent: false, // SetupIntent
            isServerSideConfirm: false // Client-side confirmation
        )
        _testDeferredConfirm(
            inputPaymentOption: .new(confirmParams: insufficient_funds_new_PM),
            expectedShouldSavePaymentMethod: false,
            expectedResult: .failed(error: ExpectedError(errorDescription: "Your card has insufficient funds.")),
            isPaymentIntent: false, // SetupIntent
            isServerSideConfirm: true // Server-side confirmation
        )
    }

    func testDeferredConfirm_saved_insufficient_funds_card() {
        let insufficient_funds_saved_PM = STPPaymentMethod(stripeId: "pm_card_visa_chargeDeclinedInsufficientFunds")
        _testDeferredConfirm(
            inputPaymentOption: .saved(paymentMethod: insufficient_funds_saved_PM),
            expectedShouldSavePaymentMethod: false,
            expectedResult: .failed(error: ExpectedError(errorDescription: "Your card has insufficient funds.")),
            isPaymentIntent: true, // PaymentIntent
            isServerSideConfirm: false // Client-side confirmation
        )
        _testDeferredConfirm(
            inputPaymentOption: .saved(paymentMethod: insufficient_funds_saved_PM),
            expectedShouldSavePaymentMethod: false,
            expectedResult: .failed(error: ExpectedError(errorDescription: "Your card has insufficient funds.")),
            isPaymentIntent: true, // PaymentIntent
            isServerSideConfirm: true // Server-side confirmation
        )
        _testDeferredConfirm(
            inputPaymentOption: .saved(paymentMethod: insufficient_funds_saved_PM),
            expectedShouldSavePaymentMethod: false,
            expectedResult: .failed(error: ExpectedError(errorDescription: "Your card has insufficient funds.")),
            isPaymentIntent: false, // SetupIntent
            isServerSideConfirm: false // Client-side confirmation
        )
        _testDeferredConfirm(
            inputPaymentOption: .saved(paymentMethod: insufficient_funds_saved_PM),
            expectedShouldSavePaymentMethod: false,
            expectedResult: .failed(error: ExpectedError(errorDescription: "Your card has insufficient funds.")),
            isPaymentIntent: false, // SetupIntent
            isServerSideConfirm: true // Server-side confirmation
        )
    }

    func _testDeferredConfirm(
        inputPaymentOption: PaymentOption,
        expectedShouldSavePaymentMethod: Bool,
        expectedResult: PaymentSheetResult,
        isPaymentIntent: Bool,
        isServerSideConfirm: Bool
    ) {
        let expectation = expectation(description: "")
        var sut_paymentMethodID: String = "" // The PM that the sut gave us
        var merchant_clientSecret: String?
        let confirmHandler: PaymentSheet.IntentConfiguration.ConfirmHandler = { paymentMethod, _, intentCreationCallback in
            sut_paymentMethodID = paymentMethod.stripeId
            let createIntentCompletion: (String?, Error?) -> Void = { clientSecret, error in
                if let clientSecret {
                    merchant_clientSecret = clientSecret
                    intentCreationCallback(.success(clientSecret))
                } else {
                    intentCreationCallback(.failure(error ?? ExpectedError()))
                }
            }
            if isPaymentIntent {
                let params: [String: Any] = isServerSideConfirm ?
                [
                    "amount": 1050,
                    "payment_method": paymentMethod.stripeId,
                    "confirm": true,
                    "payment_method_options[card][setup_future_usage]": expectedShouldSavePaymentMethod ? "off_session" : "",
                ] : [
                    "amount": 1050,
                ]
                STPTestingAPIClient.shared().createPaymentIntent(withParams: params, completion: createIntentCompletion)
            } else {
                let params: [String: Any] = isServerSideConfirm ? [
                    "confirm": "true",
                    "payment_method": paymentMethod.stripeId,
                ] : [:]
                STPTestingAPIClient.shared().createSetupIntent(withParams: params, completion: createIntentCompletion)
            }
        }
        let intentConfigMode: PaymentSheet.IntentConfiguration.Mode = {
            if isPaymentIntent {
                return .payment(amount: 1050, currency: "USD")
            } else {
                return .setup(currency: nil)
            }
        }()
        let intentConfig = PaymentSheet.IntentConfiguration(mode: intentConfigMode, confirmHandler: confirmHandler)
        let intent: Intent = .deferredIntent(
            elementsSession: ._testCardValue(),
            intentConfig: intentConfig
        )
        var configuration = self.configuration
        configuration.customer = .init(id: "", ephemeralKeySecret: "")
        PaymentSheet.confirm(
            configuration: configuration,
            authenticationContext: self,
            intent: intent,
            paymentOption: inputPaymentOption,
            paymentHandler: self.paymentHandler
        ) { result in
            XCTAssertTrue(Thread.isMainThread)
            switch (result, expectedResult) {
            case (.completed, .completed):
                if isPaymentIntent {
                    self.apiClient.retrievePaymentIntent(withClientSecret: merchant_clientSecret!) { intent, _ in
                        expectation.fulfill()
                        guard let intent else { XCTFail("Failed to retrieve Intent"); return }
                        // The PM passed to the merchant should match the PM on the succeeded intent
                        XCTAssertEqual(intent.paymentMethodId, sut_paymentMethodID)
                        // The PI should succeed
                        XCTAssertEqual(intent.status, STPPaymentIntentStatus.succeeded)
                        // The PI's sfu value should match `expectedShouldSavePaymentMethod`
                        let cardSFU = (intent.paymentMethodOptions?.allResponseFields["card"] as? [String: Any])?["setup_future_usage"] as? String
                        if expectedShouldSavePaymentMethod {
                            XCTAssertEqual(cardSFU, "off_session")
                        } else {
                            XCTAssertNil(cardSFU)
                        }
                    }
                } else {
                    self.apiClient.retrieveSetupIntent(withClientSecret: merchant_clientSecret!) { intent, _ in
                        expectation.fulfill()
                        guard let intent else { XCTFail("Failed to retrieve Intent"); return }
                        // The PM passed to the merchant should match the PM on the succeeded intent
                        XCTAssertEqual(intent.paymentMethodID, sut_paymentMethodID)
                        // The PI should succeed
                        XCTAssertEqual(intent.status, STPSetupIntentStatus.succeeded)
                    }
                }
            case (.canceled, .canceled):
                expectation.fulfill()
            case (.failed(let resultError), .failed(let expectedError)):
                // Hack: Use hasSuffix b/c the test backend prepends "Error creating PaymentIntent:" to its returned error string
                XCTAssertTrue(resultError.localizedDescription.hasSuffix(expectedError.localizedDescription))
                expectation.fulfill()
            default:
                XCTFail("Result did not match. Expected \(expectedResult) but got \(result)")
            }
        }
        waitForExpectations(timeout: 10)
    }

    func testDeferredConfirm_paymentintent_amount_doesnt_match_intent_config() {
        // More validation tests are in PaymentSheetDeferredValidatorTests; this tests we perform validation in the paymentintent confirm flow
        let e = expectation(description: "confirm completes")
        let intentConfig = PaymentSheet.IntentConfiguration(mode: .payment(amount: 1080, currency: "USD")) { _, _, intentCreationCallback in
            STPTestingAPIClient.shared().createPaymentIntent(withParams: [
                "amount": 1050,
            ]) { pi, _ in
                intentCreationCallback(.success(pi ?? ""))
            }
        }
        PaymentSheet.confirm(
            configuration: configuration,
            authenticationContext: self,
            intent: .deferredIntent(elementsSession: ._testCardValue(), intentConfig: intentConfig),
            paymentOption: .new(confirmParams: self.valid_card_checkbox_selected),
            paymentHandler: paymentHandler
        ) { result in
            e.fulfill()
            guard case let .failed(error) = result else {
                XCTFail()
                return
            }
            XCTAssertEqual((error as CustomDebugStringConvertible).debugDescription, "An error occured in PaymentSheet. Your PaymentIntent amount (1050) does not match the PaymentSheet.IntentConfiguration amount (1080).")
        }
        waitForExpectations(timeout: 10)
    }

    func testDeferredConfirm_paymentintent_server_side_confirm_doesnt_validate() {
        // More validation tests are in PaymentSheetDeferredValidatorTests; this tests we **don't** perform validation in the paymentintent server-side confirm flow
        let e = expectation(description: "confirm completes")
        let intentConfig = PaymentSheet.IntentConfiguration(mode: .payment(amount: 1080, currency: "USD")) { paymentMethod, _, intentCreationCallback in
            STPTestingAPIClient.shared().createPaymentIntent(withParams: [
                "amount": 1050,
                "confirm": true,
                "payment_method": paymentMethod.stripeId,
            ]) { pi, _ in
                intentCreationCallback(.success(pi ?? ""))
            }
        }
        PaymentSheet.confirm(
            configuration: configuration,
            authenticationContext: self,
            intent: .deferredIntent(elementsSession: ._testCardValue(), intentConfig: intentConfig),
            paymentOption: .new(confirmParams: self.valid_card_checkbox_selected),
            paymentHandler: paymentHandler
        ) { result in
            e.fulfill()
            // The result is completed, even though the IntentConfiguration and PaymentIntent amounts are not the same
            guard case .completed = result else {
                XCTFail()
                return
            }
        }
        waitForExpectations(timeout: 10)
    }

    func testDeferredConfirm_setupintent_usage_doesnt_match_intent_config() {
        // More validation tests are in PaymentSheetDeferredValidatorTests; this tests we perform validation in the setupintent confirm flow
        let e = expectation(description: "confirm completes")
        let intentConfig = PaymentSheet.IntentConfiguration(mode: .setup(currency: "USD")) { _, _, intentCreationCallback in
            STPTestingAPIClient.shared().createSetupIntent(withParams: [
                "usage": "on_session",
            ]) { si, _ in
                intentCreationCallback(.success(si ?? ""))
            }
        }
        PaymentSheet.confirm(
            configuration: configuration,
            authenticationContext: self,
            intent: .deferredIntent(elementsSession: ._testCardValue(), intentConfig: intentConfig),
            paymentOption: .new(confirmParams: self.valid_card_checkbox_selected),
            paymentHandler: paymentHandler
        ) { result in
            e.fulfill()
            guard case let .failed(error) = result else {
                XCTFail()
                return
            }
            XCTAssertEqual((error as CustomDebugStringConvertible).debugDescription, "An error occured in PaymentSheet. Your SetupIntent usage (onSession) does not match the PaymentSheet.IntentConfiguration setupFutureUsage (offSession).")
        }
        waitForExpectations(timeout: 10)
    }

    func testDeferredConfirm_setupintent_server_side_confirm_doesnt_validate() {
        // More validation tests are in PaymentSheetDeferredValidatorTests; this tests we **don't** perform validation in the SetupIntent server-side confirm flow
        let e = expectation(description: "confirm completes")
        let intentConfig = PaymentSheet.IntentConfiguration(mode: .setup(currency: "USD")) { paymentMethod, _, intentCreationCallback in
            STPTestingAPIClient.shared().createSetupIntent(withParams: [
                "usage": "on_session",
                "payment_method": paymentMethod.stripeId,
                "confirm": true,
            ]) { si, _ in
                intentCreationCallback(.success(si ?? ""))
            }
        }
        PaymentSheet.confirm(
            configuration: configuration,
            authenticationContext: self,
            intent: .deferredIntent(elementsSession: ._testCardValue(), intentConfig: intentConfig),
            paymentOption: .new(confirmParams: self.valid_card_checkbox_selected),
            paymentHandler: paymentHandler
        ) { result in
            e.fulfill()
            // The result is completed, even though the IntentConfiguration and SetupIntent setup_future_usage values are not the same
            guard case .completed = result else {
                XCTFail()
                return
            }
        }
        waitForExpectations(timeout: 10)
    }

    // MARK: - update tests

    func testUpdate() {
        var intentConfig = PaymentSheet.IntentConfiguration(mode: .payment(amount: 1000, currency: "USD")) { _, _, _ in
            // These tests don't confirm, so this is unused
        }
        let firstUpdateExpectation = expectation(description: "First update completes")
        let secondUpdateExpectation = expectation(description: "Second update completes")
        // Given a PaymentSheet.FlowController instance...
        PaymentSheet.FlowController.create(intentConfiguration: intentConfig, configuration: configuration) { result in
            switch result {
            case .success(let sut):
                // ...the vc's intent should match the initial intent config...
                XCTAssertFalse(sut.viewController.intent.isSettingUp)
                XCTAssertTrue(sut.viewController.intent.isPaymentIntent)
                // ...and updating the intent config should succeed...
                intentConfig.mode = .setup(currency: nil, setupFutureUsage: .offSession)
                sut.update(intentConfiguration: intentConfig) { error in
                    XCTAssertNil(error)
                    XCTAssertNil(sut.paymentOption)
                    XCTAssertTrue(sut.viewController.intent.isSettingUp)
                    XCTAssertFalse(sut.viewController.intent.isPaymentIntent)
                    firstUpdateExpectation.fulfill()

                    // ...updating the intent config multiple times should succeed...
                    intentConfig.mode = .payment(amount: 100, currency: "USD", setupFutureUsage: nil)
                    sut.update(intentConfiguration: intentConfig) { error in
                        XCTAssertNil(error)
                        XCTAssertNil(sut.paymentOption)
                        XCTAssertFalse(sut.viewController.intent.isSettingUp)
                        XCTAssertTrue(sut.viewController.intent.isPaymentIntent)
                        secondUpdateExpectation.fulfill()
                    }
                }
            case .failure(let error):
                XCTFail(error.nonGenericDescription)
            }
        }
        waitForExpectations(timeout: 10)
    }

    func testUpdateFails() {
        var intentConfig = PaymentSheet.IntentConfiguration(mode: .payment(amount: 1000, currency: "USD")) { _, _, _ in
            // These tests don't confirm, so this is unused
        }

        let failedUpdateExpectation = expectation(description: "First update fails")
        let secondUpdateExpectation = expectation(description: "Second update succeeds")
        PaymentSheet.FlowController.create(intentConfiguration: intentConfig, configuration: configuration) { result in
            switch result {
            case .success(let sut):
                // ...updating w/ an invalid intent config should fail...
                intentConfig.mode = .setup(currency: "Invalid currency", setupFutureUsage: .offSession)
                sut.update(intentConfiguration: intentConfig) { updateError in
                    XCTAssertNotNil(updateError)
                    // ...the paymentOption should be nil...
                    XCTAssertNil(sut.paymentOption)
                    failedUpdateExpectation.fulfill()
                    // Note: `confirm` has an assertionFailure if paymentOption is nil, so we don't check it here.

                    // ...updating should succeed after failing to update
                    intentConfig.mode = .setup(currency: "USD", setupFutureUsage: .offSession)
                    sut.update(intentConfiguration: intentConfig) { error in
                        XCTAssertNil(error)
                        // TODO(Update:) Change this to validate it preserves the paymentOption
                        XCTAssertNil(sut.paymentOption)
                        secondUpdateExpectation.fulfill()
                    }
                }
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
        }
        waitForExpectations(timeout: 10)
    }

    func testUpdateIgnoresInFlightUpdate() {
        var intentConfig = PaymentSheet.IntentConfiguration(mode: .payment(amount: 1000, currency: "USD")) { _, _, _ in
            // These tests don't confirm, so this is unused
        }

        let firstUpdateExpectation = expectation(description: "First update should not invoke callback")
        firstUpdateExpectation.isInverted = true
        let secondUpdateExpectation = expectation(description: "Second update succeeds")
        var flowController: PaymentSheet.FlowController!
        PaymentSheet.FlowController.create(intentConfiguration: intentConfig, configuration: configuration) { result in
            switch result {
            case .success(let sut):
                flowController = sut
                flowController.update(intentConfiguration: intentConfig) { _ in
                    firstUpdateExpectation.fulfill()
                }

                intentConfig.mode = .setup(currency: "USD", setupFutureUsage: .offSession)
                flowController.update(intentConfiguration: intentConfig) { error in
                    XCTAssertNil(error)
                    // TODO(Update:) Change this to validate it preserves the paymentOption
                    XCTAssertNil(flowController.paymentOption)
                    secondUpdateExpectation.fulfill()
                }
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
        }
        waitForExpectations(timeout: 10)
    }

    // MARK: - other tests

    func testMakeShippingParamsReturnsNilIfPaymentIntentHasDifferentShipping() {
        // Given a PI with shipping...
        let pi = STPFixtures.paymentIntent()
        guard let shipping = pi.shipping else {
            XCTFail("PI should contain shipping")
            return
        }
        // ...and a configuration with *a different* shipping
        var config = configuration
        // ...PaymentSheet should set shipping params on /confirm
        XCTAssertNotNil(PaymentSheet.makeShippingParams(for: pi, configuration: config))
        XCTAssertNotNil(PaymentSheet.makePaymentIntentParams(confirmPaymentMethodType: .saved(STPFixtures.paymentMethod()), paymentIntent: pi, configuration: config).shipping)

        // However, if the PI and config have the same shipping...
        config.shippingDetails = {
            return .init(
                address: AddressViewController.AddressDetails.Address(
                    city: shipping.address?.city,
                    country: shipping.address?.country ?? "pi.shipping is missing country",
                    line1: shipping.address?.line1 ?? "pi.shipping is missing line1",
                    line2: shipping.address?.line2,
                    postalCode: shipping.address?.postalCode,
                    state: shipping.address?.state
                ),
                name: pi.shipping?.name,
                phone: pi.shipping?.phone
            )
        }
        // ...PaymentSheet should not set shipping params on /confirm
        XCTAssertNil(PaymentSheet.makeShippingParams(for: pi, configuration: config))
        XCTAssertNil(PaymentSheet.makePaymentIntentParams(confirmPaymentMethodType: .saved(STPFixtures.paymentMethod()), paymentIntent: pi, configuration: config).shipping)
    }

    /// Setting SFU to `true` when a customer is set should set the parameter to `off_session`.
    func testPaymentIntentParamsWithSFUTrueAndCustomer() {
        let paymentIntentParams = STPPaymentIntentParams(clientSecret: "")
        paymentIntentParams.paymentMethodOptions = STPConfirmPaymentMethodOptions()
        paymentIntentParams.paymentMethodOptions?.setSetupFutureUsageIfNecessary(
            true,
            paymentMethodType: PaymentSheet.PaymentMethodType.card,
            customer: .init(id: "", ephemeralKeySecret: "")
        )

        let params = STPFormEncoder.dictionary(forObject: paymentIntentParams)
        guard
            let paymentMethodOptions = params["payment_method_options"] as? [String: Any],
            let card = paymentMethodOptions["card"] as? [String: Any],
            let setupFutureUsage = card["setup_future_usage"] as? String
        else {
            XCTFail("Incorrect params")
            return
        }

        XCTAssertEqual(setupFutureUsage, "off_session")
    }

    /// Setting SFU to `false` when a customer is set should set the parameter to an empty string.
    func testPaymentIntentParamsWithSFUFalseAndCustomer() {
        let paymentIntentParams = STPPaymentIntentParams(clientSecret: "")
        paymentIntentParams.paymentMethodOptions = STPConfirmPaymentMethodOptions()
        paymentIntentParams.paymentMethodOptions?.setSetupFutureUsageIfNecessary(
            false,
            paymentMethodType: PaymentSheet.PaymentMethodType.card,
            customer: .init(id: "", ephemeralKeySecret: "")
        )

        let params = STPFormEncoder.dictionary(forObject: paymentIntentParams)
        guard
            let paymentMethodOptions = params["payment_method_options"] as? [String: Any],
            let card = paymentMethodOptions["card"] as? [String: Any],
            let setupFutureUsage = card["setup_future_usage"] as? String
        else {
            XCTFail("Incorrect params")
            return
        }

        XCTAssertEqual(setupFutureUsage, "")
    }

    /// Setting SFU to `true` when no customer is set shouldn't set the parameter.
    func testPaymentIntentParamsWithSFUTrueAndNoCustomer() {
        let paymentIntentParams = STPPaymentIntentParams(clientSecret: "")
        paymentIntentParams.paymentMethodOptions = STPConfirmPaymentMethodOptions()
        paymentIntentParams.paymentMethodOptions?.setSetupFutureUsageIfNecessary(
            false,
            paymentMethodType: PaymentSheet.PaymentMethodType.card,
            customer: nil
        )

        let params = STPFormEncoder.dictionary(forObject: paymentIntentParams)
        XCTAssertEqual((params["payment_method_options"] as! [String: Any]).count, 0)
    }

    /// Setting SFU to `false` when no customer is set shouldn't set the parameter.
    func testPaymentIntentParamsWithSFUFalseAndNoCustomer() {
        let paymentIntentParams = STPPaymentIntentParams(clientSecret: "")
        paymentIntentParams.paymentMethodOptions = STPConfirmPaymentMethodOptions()
        paymentIntentParams.paymentMethodOptions?.setSetupFutureUsageIfNecessary(
            false,
            paymentMethodType: PaymentSheet.PaymentMethodType.card,
            customer: nil
        )

        let params = STPFormEncoder.dictionary(forObject: paymentIntentParams)
        XCTAssertEqual((params["payment_method_options"] as! [String: Any]).count, 0)
    }

    func testMakeIntentParams_always_sets_paymentMethodType() {
        let examplePaymentMethodParams = STPPaymentMethodParams(card: STPFixtures.paymentMethodCardParams(), billingDetails: nil, metadata: nil)
        let examplePaymentMethod = STPFixtures.paymentMethod()
        var configuration = PaymentSheet.Configuration._testValue_MostPermissive()
        configuration.customer = .init(id: "id", ephemeralKeySecret: "ek")
        let confirmTypes: [PaymentSheet.ConfirmPaymentMethodType] = [
            .new(params: examplePaymentMethodParams, shouldSave: false),
            .new(params: examplePaymentMethodParams, paymentMethod: examplePaymentMethod, shouldSave: false),
            .saved(examplePaymentMethod),
        ]
        for confirmType in confirmTypes {
            let pi_params = PaymentSheet.makePaymentIntentParams(
                confirmPaymentMethodType: confirmType,
                paymentIntent: STPFixtures.paymentIntent(),
                configuration: configuration
            )
            XCTAssertEqual(pi_params.paymentMethodType, .card)
            XCTAssertEqual(pi_params.returnURL, configuration.returnURL)
            if pi_params.paymentMethodParams == nil {
                XCTAssertEqual(pi_params.paymentMethodId, examplePaymentMethod.stripeId)
            }
            let si_params = PaymentSheet.makeSetupIntentParams(
                confirmPaymentMethodType: confirmType,
                setupIntent: STPFixtures.setupIntent(),
                configuration: configuration
            )
            XCTAssertEqual(si_params.paymentMethodType, .card)
            XCTAssertEqual(si_params.returnURL, configuration.returnURL)
            if si_params.paymentMethodParams == nil {
                XCTAssertEqual(si_params.paymentMethodID, examplePaymentMethod.stripeId)
            }
        }
    }

    func testMakeIntentParams_paypal_sets_mandate() {
        let paypalPaymentMethodParams = STPPaymentMethodParams(payPal: .init(), billingDetails: nil, metadata: nil)
        let paypalPaymentMethod = STPPaymentMethod.decodedObject(fromAPIResponse: ["id": "pm_123", "type": "paypal"])!
        var configuration = PaymentSheet.Configuration._testValue_MostPermissive()
        configuration.customer = .init(id: "id", ephemeralKeySecret: "ek")
        // Confirming w/ a new Paypal PM...
        let confirmTypes: [PaymentSheet.ConfirmPaymentMethodType] = [
            .new(params: paypalPaymentMethodParams, shouldSave: false),
            .new(params: paypalPaymentMethodParams, paymentMethod: paypalPaymentMethod, shouldSave: false),
        ]

        for confirmType in confirmTypes {
            // Params for pi without SFU supplied...
            let params_for_pi_without_sfu = PaymentSheet.makePaymentIntentParams(
                confirmPaymentMethodType: confirmType,
                paymentIntent: STPFixtures.makePaymentIntent(),
                configuration: configuration
            )
            // ...shouldn't have mandate data
            XCTAssertNil(params_for_pi_without_sfu.mandateData)
            // Params for pi with SFU supplied...
            let params_for_pi_with_sfu = PaymentSheet.makePaymentIntentParams(
                confirmPaymentMethodType: confirmType,
                paymentIntent: STPFixtures.makePaymentIntent(setupFutureUsage: .offSession),
                configuration: configuration
            )
            // ...should have mandate data
            XCTAssertNotNil(params_for_pi_with_sfu.mandateData)
            XCTAssert(params_for_pi_with_sfu.mandateData != nil)
            // Params for si
            let params_for_si_with_sfu = PaymentSheet.makeSetupIntentParams(
                confirmPaymentMethodType: confirmType,
                setupIntent: STPFixtures.setupIntent(),
                configuration: configuration
            )
            // ...should have mandate data
            XCTAssertNotNil(params_for_si_with_sfu.mandateData)
        }
    }

    // MARK: - helper methods
    func fetchPaymentIntent(
        types: [String],
        currency: String = "eur",
        paymentMethodID: String? = nil,
        confirm: Bool = false
    ) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            fetchPaymentIntent(
                types: types,
                currency: currency,
                paymentMethodID: paymentMethodID,
                confirm: confirm
            ) { result in
                continuation.resume(with: result)
            }
        }
    }

    func fetchPaymentIntent(
        types: [String],
        currency: String = "eur",
        paymentMethodID: String? = nil,
        confirm: Bool = false,
        completion: @escaping (Result<(String), Error>) -> Void
    ) {
        var params = [String: Any]()
        params["amount"] = 1050
        params["currency"] = currency
        params["payment_method_types"] = types
        params["confirm"] = confirm
        if let paymentMethodID = paymentMethodID {
            params["payment_method"] = paymentMethodID
        }

        STPTestingAPIClient
            .shared()
            .createPaymentIntent(
                withParams: params
            ) { clientSecret, error in
                guard let clientSecret = clientSecret,
                      error == nil
                else {
                    completion(.failure(error!))
                    return
                }

                completion(.success(clientSecret))
            }
    }

    func fetchSetupIntent(types: [String], completion: @escaping (Result<(String), Error>) -> Void)
    {
        STPTestingAPIClient
            .shared()
            .createSetupIntent(
                withParams: [
                    "payment_method_types": types,
                ]
            ) { clientSecret, error in
                guard let clientSecret = clientSecret,
                      error == nil
                else {
                    completion(.failure(error!))
                    return
                }

                completion(.success(clientSecret))
            }
    }
}

extension PaymentSheetAPITest: STPAuthenticationContext {
    func authenticationPresentingViewController() -> UIViewController {
        return UIViewController()
    }
}
