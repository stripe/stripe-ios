//
//  PaymentSheetLoaderTest.swift
//  StripeiOSTests
//
//  Created by Yuki Tokuhiro on 6/24/23.
//

@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripeCoreTestUtils
@testable@_spi(STP) import StripePayments
@testable @_spi(STP)@_spi(ExternalPaymentMethodsPrivateBeta) import StripePaymentSheet
@testable@_spi(STP) import StripePaymentsTestUtils
import XCTest

final class PaymentSheetLoaderTest: XCTestCase {
    let apiClient = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)
    lazy var configuration: PaymentSheet.Configuration = {
        var config = PaymentSheet.Configuration()
        config.apiClient = apiClient
        return config
    }()

    func testPaymentSheetLoadWithPaymentIntent() async throws {
        let expectation = XCTestExpectation(description: "Load w/ PaymentIntent")
        let types = ["ideal", "card", "bancontact", "sofort"]
        let clientSecret = try await STPTestingAPIClient.shared.fetchPaymentIntent(types: types)
        // Given a PaymentIntent client secret...
        PaymentSheetLoader.load(mode: .paymentIntentClientSecret(clientSecret), configuration: self.configuration) { result in
            expectation.fulfill()
            switch result {
            case .success(let intent, let paymentMethods, _):
                // ...PaymentSheet should successfully load
                guard case let .paymentIntent(elementsSession, paymentIntent) = intent else {
                    XCTFail()
                    return
                }
                // Sanity check that the ElementsSession object contain the types in the PI
                XCTAssertEqual(
                    Set(elementsSession.orderedPaymentMethodTypes.map { $0.identifier }),
                    Set(types)
                )
                // Sanity check the PI matches the one we fetched
                XCTAssertEqual(paymentIntent.clientSecret, clientSecret)
                XCTAssertEqual(paymentMethods, [])
                XCTAssertTrue(intent.isApplePayEnabled)
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
            configuration: self.configuration
        ) { result in
            switch result {
            case .success(let setupIntent, let paymentMethods, _):
                XCTAssertEqual(
                    Set(setupIntent.recommendedPaymentMethodTypes),
                    Set(expected)
                )
                XCTAssertEqual(paymentMethods, [])
                XCTAssertTrue(setupIntent.isApplePayEnabled)
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

    func testPaymentSheetLoadDeferredIntentSucceeds() {
        let loadExpectation = XCTestExpectation(description: "Load PaymentSheet")
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
        loadExpectation.expectedFulfillmentCount = intentConfigTestcases.count
        for (index, intentConfig) in intentConfigTestcases.enumerated() {
            PaymentSheetLoader.load(mode: .deferredIntent(intentConfig), configuration: self.configuration) { result in
                loadExpectation.fulfill()
                switch result {
                case .success(let intent, _, _):
                    guard case .deferredIntent = intent else {
                        XCTFail()
                        return
                    }
                    XCTAssertTrue(intent.isApplePayEnabled)
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
        // Test PaymentSheetLoader.load can load various IntentConfigurations
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
            PaymentSheetLoader.load(mode: .deferredIntent(intentConfig), configuration: self.configuration) { result in
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

    func testPaymentSheetLoadFiltersSavedApplePayCards() async throws {
        let apiClient = STPAPIClient(publishableKey: STPTestingJPPublishableKey)
        var configuration = PaymentSheet.Configuration()
        configuration.apiClient = apiClient

        // A hardcoded test Customer
        let testCustomerID = "cus_OtOGvD0ZVacBoj"

        // Create a new EK for the Customer
        let customerAndEphemeralKey = try await STPTestingAPIClient().fetchCustomerAndEphemeralKey(customerID: testCustomerID, merchantCountry: "jp")
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
        PaymentSheetLoader.load(mode: .deferredIntent(intentConfig), configuration: configuration) { result in
            loadExpectation.fulfill()
            switch result {
            case .success(_, let savedPaymentMethods, _):
                // ...check that it only loads the one normal saved card
                XCTAssertEqual(savedPaymentMethods.count, 1)
                XCTAssertEqual(savedPaymentMethods.first?.stripeId, savedNonApplePayCard)
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
            externalPaymentMethods: ["external_fawry", "external_fonix"],
            externalPaymentMethodConfirmHandler: { _, _, _ in /* no-op */ }
        )
        PaymentSheetLoader.load(mode: .paymentIntentClientSecret(clientSecret), configuration: configuration) { result in
            expectation.fulfill()
            switch result {
            case .success(let intent, let paymentMethods, _):
                // ...PaymentSheet should successfully load
                guard case let .paymentIntent(elementsSession, paymentIntent) = intent else {
                    XCTFail()
                    return
                }
                // Sanity check that the ElementsSession object contain the types in the PI
                XCTAssertEqual(
                    elementsSession.externalPaymentMethods.map { $0.type },
                    ["external_fawry", "external_fonix"]
                )
                // Sanity check the PI matches the one we fetched
                XCTAssertEqual(paymentIntent.clientSecret, clientSecret)
                XCTAssertEqual(paymentMethods, [])
                XCTAssertTrue(intent.isApplePayEnabled)
            case .failure(let error):
                XCTFail(error.nonGenericDescription)
            }
        }
        await fulfillment(of: [expectation], timeout: STPTestingNetworkRequestTimeout)
    }

    func testPaymentSheetLoadWithInvalidExternalPaymentMethods() async throws {
        // Loading PaymentSheet...
        let expectation = XCTestExpectation(description: "Load w/ PaymentIntent")
        let types = ["ideal", "card", "bancontact", "sofort"]
        let clientSecret = try await STPTestingAPIClient.shared.fetchPaymentIntent(types: types)
        var configuration = self.configuration
        // ...with valid external payment methods configured...
        configuration.externalPaymentMethodConfiguration = .init(
            externalPaymentMethods: ["external_invalid_value"],
            externalPaymentMethodConfirmHandler: { _, _, _ in /* no-op */ }
        )
        PaymentSheetLoader.load(mode: .paymentIntentClientSecret(clientSecret), configuration: configuration) { result in
            expectation.fulfill()
            switch result {
            case .success(let intent, let paymentMethods, _):
                // ...PaymentSheet should successfully load
                guard case let .paymentIntent(elementsSession, paymentIntent) = intent else {
                    XCTFail()
                    return
                }
                // Sanity check the PI matches the one we fetched
                XCTAssertEqual(paymentIntent.clientSecret, clientSecret)
                XCTAssertEqual(paymentMethods, [])
                XCTAssertTrue(intent.isApplePayEnabled)

                // ...with an empty `externalPaymentMethods` property
                XCTAssertTrue(elementsSession.externalPaymentMethods.isEmpty)
                // ...and not send a failure analytic
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
            PaymentSheetLoader.load(mode: .deferredIntent(intentConfig), configuration: configuration) { result in
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
