//
//  PaymentSheetLoaderTest.swift
//  StripeiOSTests
//
//  Created by Yuki Tokuhiro on 6/24/23.
//

@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripeCoreTestUtils
@testable@_spi(STP) import StripePayments
@testable @_spi(STP) @_spi(CardBrandFilteringBeta) import StripePaymentSheet
@testable@_spi(STP) import StripePaymentsTestUtils
@testable@_spi(STP) import StripeUICore
import XCTest

final class PaymentSheetLoaderTest: STPNetworkStubbingTestCase {

    var apiClient: STPAPIClient!

    override func setUp() {
        super.setUp()
        self.apiClient = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)
    }
    lazy var configuration: PaymentSheet.Configuration = {
        var config = PaymentSheet.Configuration()
        config.apiClient = apiClient
        config.applePay = .init(merchantId: "foo", merchantCountryCode: "US")
        return config
    }()

    override func tearDown() {
        STPAnalyticsClient.sharedClient._testLogHistory = []
        super.tearDown()
    }

    @MainActor
    func testPaymentSheetLoadWithPaymentIntent() async throws {
        let expectation = XCTestExpectation(description: "Load w/ PaymentIntent")
        let types = ["ideal", "card", "bancontact", "sofort"]
        let clientSecret = try await STPTestingAPIClient.shared.fetchPaymentIntent(types: types)
        // Given a PaymentIntent client secret...
        PaymentSheetLoader.load(mode: .paymentIntentClientSecret(clientSecret), configuration: self.configuration, analyticsHelper: .init(integrationShape: .complete, configuration: configuration), integrationShape: .complete) { result in
            expectation.fulfill()
            switch result {
            case .success(let loadResult):
                // ...PaymentSheet should successfully load
                guard case let .paymentIntent(paymentIntent) = loadResult.intent else {
                    XCTFail()
                    return
                }
                // Sanity check that the ElementsSession object contain the types in the PI
                XCTAssertEqual(
                    Set(loadResult.elementsSession.orderedPaymentMethodTypes.map { $0.identifier }),
                    Set(types)
                )
                // Sanity check the PI matches the one we fetched
                XCTAssertEqual(paymentIntent.clientSecret, clientSecret)
                XCTAssertEqual(loadResult.savedPaymentMethods, [])
                XCTAssertTrue(PaymentSheet.isApplePayEnabled(elementsSession: loadResult.elementsSession, configuration: self.configuration))
            case .failure(let error):
                XCTFail(error.nonGenericDescription)
            }
        }
        await fulfillment(of: [expectation], timeout: STPTestingNetworkRequestTimeout)
    }

    func testPaymentSheetLoadWithSetupIntent() async throws {
        let expectation = XCTestExpectation(description: "Retrieve Setup Intent With Preferences")
        let types = ["ideal", "card", "bancontact", "sofort"]
        let expected: [STPPaymentMethodType] = [.card, .iDEAL, .bancontact, .sofort]
        let clientSecret = try await STPTestingAPIClient.shared.fetchSetupIntent(types: types)
        PaymentSheetLoader.load(
            mode: .setupIntentClientSecret(clientSecret),
            configuration: self.configuration,
            analyticsHelper: .init(integrationShape: .complete, configuration: configuration),
            integrationShape: .complete
        ) { result in
            switch result {
            case .success(let loadResult):
                XCTAssertEqual(
                    Set(loadResult.elementsSession.orderedPaymentMethodTypes),
                    Set(expected)
                )
                XCTAssertEqual(loadResult.savedPaymentMethods, [])
                XCTAssertTrue(PaymentSheet.isApplePayEnabled(elementsSession: loadResult.elementsSession, configuration: self.configuration))
                expectation.fulfill()
            case .failure(let error):
                XCTFail()
                print(error)
            }
        }
        await fulfillment(of: [expectation], timeout: STPTestingNetworkRequestTimeout)
    }

    func testPaymentSheetLoadWithSetupIntentAttachedPaymentMethod() {
        let expectation = XCTestExpectation(
            description: "Load SetupIntent with an attached payment method"
        )
        STPTestingAPIClient.shared.createSetupIntent(withParams: [
            "payment_method": "pm_card_visa",
        ]) { clientSecret, error in
            guard let clientSecret = clientSecret, error == nil else {
                XCTFail()
                expectation.fulfill()
                return
            }

            PaymentSheetLoader.load(
                mode: .setupIntentClientSecret(clientSecret),
                configuration: self.configuration,
                analyticsHelper: .init(integrationShape: .complete, configuration: self.configuration),
                integrationShape: .complete
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

    func testPaymentSheetLoadDeferredIntentSucceeds() {
        // Test PaymentSheetLoader.load can load various IntentConfigurations
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
        for (index, intentConfig) in intentConfigTestcases.enumerated() {
            let loadExpectation = XCTestExpectation(description: "Load PaymentSheet")
            PaymentSheetLoader.load(mode: .deferredIntent(intentConfig), configuration: self.configuration, analyticsHelper: .init(integrationShape: .flowController, configuration: configuration), integrationShape: .flowController) { result in
                switch result {
                case .success(let loadResult):
                    guard case .deferredIntent = loadResult.intent else {
                        XCTFail()
                        return
                    }
                    XCTAssertTrue(PaymentSheet.isApplePayEnabled(elementsSession: loadResult.elementsSession, configuration: self.configuration))
                case .failure(let error):
                    XCTFail("Test case at index \(index) failed: \(error)")
                    print(error)
                }
                loadExpectation.fulfill()
            }
            wait(for: [loadExpectation], timeout: STPTestingNetworkRequestTimeout)
        }
    }

    func testPaymentSheetLoadDeferredIntentFails() {
        let analyticsHelper = PaymentSheetAnalyticsHelper(integrationShape: .complete, configuration: configuration, analyticsClient: STPAnalyticsClient())
        let loadExpectation = XCTestExpectation(description: "Load PaymentSheet")
        // Test PaymentSheetLoader.load can load various IntentConfigurations
        let confirmHandler: PaymentSheet.IntentConfiguration.ConfirmHandler = {_, _, _ in
            XCTFail("Confirm handler shouldn't be called.")
        }
        let intentConfigTestcases: [(config: PaymentSheet.IntentConfiguration, expectedErrorType: String)] = [
            // Bad currency
            (.init(mode: .payment(amount: 1000, currency: "FOO"), confirmHandler: confirmHandler), "invalid_request_error"),
            // Bad amount
            (.init(mode: .payment(amount: 0, currency: "USD"), paymentMethodTypes: ["card"], confirmHandler: confirmHandler), "StripePaymentSheet.PaymentSheetError"),
            // Bad pm type
            (.init(mode: .setup(currency: "USD"), paymentMethodTypes: ["card", "foo"], confirmHandler: confirmHandler), "invalid_request_error"),
            // Bad OBO
            (.init(mode: .setup(currency: "USD"), paymentMethodTypes: ["card"], onBehalfOf: "foo", confirmHandler: confirmHandler), "invalid_request_error"),
        ]
        loadExpectation.expectedFulfillmentCount = intentConfigTestcases.count
        for (index, testcase) in intentConfigTestcases.enumerated() {
            PaymentSheetLoader.load(mode: .deferredIntent(testcase.config), configuration: self.configuration, analyticsHelper: analyticsHelper, integrationShape: .complete) { result in
                loadExpectation.fulfill()
                switch result {
                case .success:
                    XCTFail("Test case at index \(index) succeeded to load but it should have failed.")
                case .failure:
                    break
                }
                // Should send a load failure analytic
                let analyticEvent = analyticsHelper.analyticsClient._testLogHistory.last
                XCTAssertEqual(analyticEvent?["error_type"] as? String, testcase.expectedErrorType)
                XCTAssertNotNil(analyticEvent?["error_code"] as? String)
            }
        }
        wait(for: [loadExpectation], timeout: STPTestingNetworkRequestTimeout)
    }

    func testPaymentSheetLoadDoesNotFilterSavedApplePayCardsWhenDisabled() async throws {
        let apiClient = STPAPIClient(publishableKey: STPTestingJPPublishableKey)
        var configuration = PaymentSheet.Configuration()
        configuration.apiClient = apiClient
        configuration.disableWalletPaymentMethodFiltering = true
        // A hardcoded test Customer
        let testCustomerID = "cus_OtOGvD0ZVacBoj"

        // Create a new EK for the Customer
        let customerAndEphemeralKey = try await STPTestingAPIClient.shared().fetchCustomerAndEphemeralKey(customerID: testCustomerID, merchantCountry: "jp")
        configuration.customer = .init(id: testCustomerID, ephemeralKeySecret: customerAndEphemeralKey.ephemeralKeySecret)

        // This is a saved Apple Pay card:
        let savedApplePayCard = "pm_1O5bTlIq2LmpyICoB8eZH4BJ"
        // This is a normal saved card:
        let savedNonApplePayCard = "card_1O5upWIq2LmpyICo9tQmU9xY"

        // Check that the test Customer has the expected cards
        let checkCustomerExpectation = expectation(description: "Check test customer")
        apiClient.listPaymentMethods(forCustomer: testCustomerID, using: customerAndEphemeralKey.ephemeralKeySecret) { paymentMethods, _ in
            XCTAssertEqual(paymentMethods?.first?.stripeId, savedApplePayCard)
            XCTAssertEqual(paymentMethods?.last?.stripeId, savedNonApplePayCard)
            checkCustomerExpectation.fulfill()
        }
        await fulfillment(of: [checkCustomerExpectation])

        // Load PaymentSheet...
        let loadExpectation = XCTestExpectation(description: "Load PaymentSheet")
        let confirmHandler: PaymentSheet.IntentConfiguration.ConfirmHandler = {_, _, _ in
            XCTFail("Confirm handler shouldn't be called.")
        }
        let intentConfig = PaymentSheet.IntentConfiguration(mode: .payment(amount: 1000, currency: "JPY"), confirmHandler: confirmHandler)
        PaymentSheetLoader.load(mode: .deferredIntent(intentConfig), configuration: configuration, analyticsHelper: .init(integrationShape: .flowController, configuration: configuration), integrationShape: .flowController) { result in
            loadExpectation.fulfill()
            switch result {
            case .success(let loadResult):
                // ...check that it only loads the one normal saved card
                XCTAssertEqual(loadResult.savedPaymentMethods.count, 2)
                XCTAssertEqual(loadResult.savedPaymentMethods.map(\.stripeId), [savedApplePayCard, savedNonApplePayCard])
            case .failure:
                XCTFail()
            }
        }
        await fulfillment(of: [loadExpectation], timeout: STPTestingNetworkRequestTimeout)
    }
    
    func testPaymentSheetLoadFiltersSavedApplePayCards() async throws {
        let apiClient = STPAPIClient(publishableKey: STPTestingJPPublishableKey)
        var configuration = PaymentSheet.Configuration()
        configuration.apiClient = apiClient

        // A hardcoded test Customer
        let testCustomerID = "cus_OtOGvD0ZVacBoj"

        // Create a new EK for the Customer
        let customerAndEphemeralKey = try await STPTestingAPIClient.shared().fetchCustomerAndEphemeralKey(customerID: testCustomerID, merchantCountry: "jp")
        configuration.customer = .init(id: testCustomerID, ephemeralKeySecret: customerAndEphemeralKey.ephemeralKeySecret)

        // This is a saved Apple Pay card:
        let savedApplePayCard = "pm_1O5bTlIq2LmpyICoB8eZH4BJ"
        // This is a normal saved card:
        let savedNonApplePayCard = "card_1O5upWIq2LmpyICo9tQmU9xY"

        // Check that the test Customer has the expected cards
        let checkCustomerExpectation = expectation(description: "Check test customer")
        apiClient.listPaymentMethods(forCustomer: testCustomerID, using: customerAndEphemeralKey.ephemeralKeySecret) { paymentMethods, _ in
            XCTAssertEqual(paymentMethods?.first?.stripeId, savedApplePayCard)
            XCTAssertEqual(paymentMethods?.last?.stripeId, savedNonApplePayCard)
            checkCustomerExpectation.fulfill()
        }
        await fulfillment(of: [checkCustomerExpectation])

        // Load PaymentSheet...
        let loadExpectation = XCTestExpectation(description: "Load PaymentSheet")
        let confirmHandler: PaymentSheet.IntentConfiguration.ConfirmHandler = {_, _, _ in
            XCTFail("Confirm handler shouldn't be called.")
        }
        let intentConfig = PaymentSheet.IntentConfiguration(mode: .payment(amount: 1000, currency: "JPY"), confirmHandler: confirmHandler)
        PaymentSheetLoader.load(mode: .deferredIntent(intentConfig), configuration: configuration, analyticsHelper: .init(integrationShape: .flowController, configuration: configuration), integrationShape: .flowController) { result in
            loadExpectation.fulfill()
            switch result {
            case .success(let loadResult):
                // ...check that it only loads the one normal saved card
                XCTAssertEqual(loadResult.savedPaymentMethods.count, 1)
                XCTAssertEqual(loadResult.savedPaymentMethods.first?.stripeId, savedNonApplePayCard)
            case .failure:
                XCTFail()
            }
        }
        await fulfillment(of: [loadExpectation], timeout: STPTestingNetworkRequestTimeout)
    }

    func testPaymentSheetLoadWithExternalPaymentMethods() async throws {
        // Loading PaymentSheet...
        let expectation = XCTestExpectation(description: "Load w/ PaymentIntent")
        let types = ["ideal", "card", "bancontact", "sofort"]
        let clientSecret = try await STPTestingAPIClient.shared.fetchPaymentIntent(types: types)
        var configuration = self.configuration
        // ...with valid external payment methods configured...
        configuration.externalPaymentMethodConfiguration = .init(
            externalPaymentMethods: ["external_paypal"],
            externalPaymentMethodConfirmHandler: { _, _, _ in /* no-op */ }
        )
        PaymentSheetLoader.load(mode: .paymentIntentClientSecret(clientSecret), configuration: configuration, analyticsHelper: .init(integrationShape: .complete, configuration: configuration), integrationShape: .complete) { result in
            expectation.fulfill()
            switch result {
            case .success(let loadResult):
                // ...PaymentSheet should successfully load
                guard case let .paymentIntent(paymentIntent) = loadResult.intent else {
                    XCTFail()
                    return
                }
                // ...and elements sessions response should contain the configured external payment methods
                XCTAssertEqual(
                    loadResult.elementsSession.externalPaymentMethods.map { $0.type },
                    ["external_paypal"]
                )
                XCTAssertEqual(
                    loadResult.elementsSession.externalPaymentMethods.first?.label,
                    "PayPal"
                )
                // Sanity check the PI matches the one we fetched
                XCTAssertEqual(paymentIntent.clientSecret, clientSecret)
                XCTAssertEqual(loadResult.savedPaymentMethods, [])
                XCTAssertTrue(PaymentSheet.isApplePayEnabled(elementsSession: loadResult.elementsSession, configuration: self.configuration))
            case .failure(let error):
                XCTFail(error.nonGenericDescription)
            }
        }
        await fulfillment(of: [expectation], timeout: STPTestingNetworkRequestTimeout)
    }

    func testPaymentSheetLoadWithInvalidExternalPaymentMethods() async throws {
        STPAnalyticsClient.sharedClient._testLogHistory = []
        // Loading PaymentSheet...
        let expectation = XCTestExpectation(description: "Load w/ PaymentIntent")
        let types = ["ideal", "card", "bancontact", "sofort"]
        let clientSecret = try await STPTestingAPIClient.shared.fetchPaymentIntent(types: types)
        var configuration = self.configuration
        // ...with invalid external payment methods configured...
        configuration.externalPaymentMethodConfiguration = .init(
            externalPaymentMethods: ["external_invalid_value"],
            externalPaymentMethodConfirmHandler: { _, _, _ in /* no-op */ }
        )
        PaymentSheetLoader.load(mode: .paymentIntentClientSecret(clientSecret), configuration: configuration, analyticsHelper: .init(integrationShape: .flowController, configuration: configuration), integrationShape: .flowController) { result in
            expectation.fulfill()
            switch result {
            case .success(let loadResult):
                // ...PaymentSheet should *still* successfully load
                guard case let .paymentIntent(paymentIntent) = loadResult.intent else {
                    XCTFail()
                    return
                }
                // Sanity check the PI matches the one we fetched
                XCTAssertEqual(paymentIntent.clientSecret, clientSecret)
                XCTAssertEqual(loadResult.savedPaymentMethods, [])
                XCTAssertTrue(PaymentSheet.isApplePayEnabled(elementsSession: loadResult.elementsSession, configuration: configuration))

                // ...with an empty `externalPaymentMethods` property
                XCTAssertTrue(loadResult.elementsSession.externalPaymentMethods.isEmpty)
                // ...and shouldn't send a load failure analytic
                let analyticEvents = STPAnalyticsClient.sharedClient._testLogHistory
                XCTAssertFalse(analyticEvents.contains(where: { dict in
                    (dict["event"] as? String) == STPAnalyticEvent.paymentSheetElementsSessionEPMLoadFailed.rawValue
                }))
            case .failure(let error):
                XCTFail(error.nonGenericDescription)
            }
        }
        await fulfillment(of: [expectation], timeout: STPTestingNetworkRequestTimeout)
    }

    func testPaymentSheetLoadFiltersCardBrandAcceptance() async throws {
        let apiClient = STPAPIClient(publishableKey: STPTestingJPPublishableKey)
        var configuration = PaymentSheet.Configuration()
        configuration.apiClient = apiClient
        configuration.cardBrandAcceptance = .disallowed(brands: [.visa])

        // A hardcoded test Customer
        let testCustomerID = "cus_OtOGvD0ZVacBoj"

        // Create a new EK for the Customer
        let customerAndEphemeralKey = try await STPTestingAPIClient.shared().fetchCustomerAndEphemeralKey(customerID: testCustomerID, merchantCountry: "jp")
        configuration.customer = .init(id: testCustomerID, ephemeralKeySecret: customerAndEphemeralKey.ephemeralKeySecret)

        // This is a Visa saved card:
        let savedCard = "card_1O5upWIq2LmpyICo9tQmU9xY"

        // Check that the test Customer has the expected cards
        let checkCustomerExpectation = expectation(description: "Check test customer")
        apiClient.listPaymentMethods(forCustomer: testCustomerID, using: customerAndEphemeralKey.ephemeralKeySecret) { paymentMethods, _ in
            XCTAssertEqual(paymentMethods?.last?.stripeId, savedCard)
            checkCustomerExpectation.fulfill()
        }
        await fulfillment(of: [checkCustomerExpectation])

        // Load PaymentSheet...
        let loadExpectation = XCTestExpectation(description: "Load PaymentSheet")
        let confirmHandler: PaymentSheet.IntentConfiguration.ConfirmHandler = {_, _, _ in
            XCTFail("Confirm handler shouldn't be called.")
        }
        let intentConfig = PaymentSheet.IntentConfiguration(mode: .payment(amount: 1000, currency: "JPY"), confirmHandler: confirmHandler)
        PaymentSheetLoader.load(mode: .deferredIntent(intentConfig), configuration: configuration, analyticsHelper: .init(integrationShape: .complete, configuration: configuration), integrationShape: .complete) { result in
            loadExpectation.fulfill()
            switch result {
            case .success(let loadResult):
                // ...check that it filters out the saved Visa card
                XCTAssertTrue(loadResult.savedPaymentMethods.isEmpty)

            case .failure:
                XCTFail()
            }
        }
        await fulfillment(of: [loadExpectation], timeout: STPTestingNetworkRequestTimeout)
    }

    func testLoadPerformance() {
        let confirmHandler: PaymentSheet.IntentConfiguration.ConfirmHandler = { _, _, _ in }
        let intentConfig = PaymentSheet.IntentConfiguration(mode: .payment(amount: 1050, currency: "USD"),
                                                            confirmHandler: confirmHandler)
        var configuration = PaymentSheet.Configuration._testValue_MostPermissive()
        configuration.apiClient = apiClient

        let options = XCTMeasureOptions()
        options.iterationCount = 0
        // ☝️ iterationCount is 0 because this isn't a good automated unit test (it makes live network requests)
        // Set it to another number to manually run if you're making changes to load and want to measure its performance.
        measure(options: options) {
            let e = expectation(description: "")
            PaymentSheetLoader.load(mode: .deferredIntent(intentConfig), configuration: configuration, analyticsHelper: .init(integrationShape: .flowController, configuration: configuration), integrationShape: .flowController) { result in
                switch result {
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                case .success:
                    break
                }
                e.fulfill()
            }
            waitForExpectations(timeout: 5)
        }
    }
}
