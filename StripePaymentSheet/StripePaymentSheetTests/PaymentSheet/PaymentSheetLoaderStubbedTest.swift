//
//  PaymentSheetLoaderMockedTest.swift
//  StripePaymentSheetTests
//

@testable import StripePaymentSheet

import OHHTTPStubs
import OHHTTPStubsSwift
@_spi(STP) @testable import StripeCore
@_spi(STP) import StripeCoreTestUtils
import XCTest

class PaymentSheetLoaderStubbedTest: APIStubbedTestCase {
    private func configuration(apiClient: STPAPIClient) -> PaymentSheet.Configuration {
        var config = PaymentSheet.Configuration()
        config.apiClient = apiClient

        let customer = PaymentSheet.CustomerConfiguration(id: "123", ephemeralKeySecret: "ek_456")
        config.customer = customer
        config.allowsDelayedPaymentMethods = true
        config.applePay = .init(merchantId: "foo", merchantCountryCode: "US")
        return config
    }

    func testReturningCustomerWithNoSavedCards() throws {
        StubbedBackend.stubPaymentMethods(fileMock: .saved_payment_methods_200, pmType: "card")
        StubbedBackend.stubPaymentMethods(fileMock: .saved_payment_methods_200, pmType: "us_bank_account")
        StubbedBackend.stubPaymentMethods(fileMock: .saved_payment_methods_200, pmType: "sepa_debit")
        StubbedBackend.stubSessions(paymentMethods: "\"card\", \"us_bank_account\"")

        let loaded = expectation(description: "Loaded")
        let analyticsClient = STPTestingAnalyticsClient()
        var configuration = self.configuration(apiClient: stubbedAPIClient())
        configuration.applePay = nil

        PaymentSheetLoader.load(
            mode: .paymentIntentClientSecret("pi_12345_secret_54321"),
            configuration: configuration,
            analyticsHelper: .init(integrationShape: .flowController, configuration: configuration, analyticsClient: analyticsClient),
            integrationShape: .flowController
        ) { result in
            switch result {
            case .success(let loadResult):
                guard case .paymentIntent(let paymentIntent) = loadResult.intent else {
                    XCTFail("Expecting payment intent")
                    return
                }
                XCTAssertFalse(PaymentSheet.isApplePayEnabled(elementsSession: loadResult.elementsSession, configuration: configuration))
                XCTAssertEqual(paymentIntent.stripeId, "pi_3Kth")
                XCTAssertEqual(loadResult.savedPaymentMethods.count, 0)
                // The last analytic should be a load succeeded event w/ selected_lpm set
                let lastAnalytic = analyticsClient.events.last
                XCTAssertEqual(lastAnalytic?.event, .paymentSheetLoadSucceeded)
                XCTAssertEqual(lastAnalytic?.params["selected_lpm"] as? String, "none")
                loaded.fulfill()
            case .failure(let error):
                XCTFail(error.nonGenericDescription)
            }
        }
        wait(for: [loaded], timeout: 2)
    }

    func testReturningCustomerWithSingleSavedCard() throws {
        StubbedBackend.stubPaymentMethods(fileMock: .saved_payment_methods_withCard_200, pmType: "card")
        StubbedBackend.stubPaymentMethods(fileMock: .saved_payment_methods_200, pmType: "us_bank_account")
        StubbedBackend.stubPaymentMethods(fileMock: .saved_payment_methods_200, pmType: "sepa_debit")
        StubbedBackend.stubSessions(paymentMethods: "\"card\", \"us_bank_account\"")

        let loaded = expectation(description: "Loaded")
        let analyticsClient = STPTestingAnalyticsClient()
        var configuration = self.configuration(apiClient: stubbedAPIClient())
        configuration.applePay = nil
        PaymentSheetLoader.load(
            mode: .paymentIntentClientSecret("pi_12345_secret_54321"),
            configuration: configuration,
            analyticsHelper: .init(integrationShape: .flowController, configuration: configuration, analyticsClient: analyticsClient),
            integrationShape: .flowController
        ) { result in
            switch result {
            case .success(let loadResult):
                guard case .paymentIntent(let paymentIntent) = loadResult.intent else {
                    XCTFail("Expecting payment intent")
                    return
                }
                XCTAssertEqual(paymentIntent.stripeId, "pi_3Kth")
                XCTAssertEqual(loadResult.savedPaymentMethods.count, 1)
                XCTAssertEqual(loadResult.savedPaymentMethods[0].type, .card)
                // The last analytic should be a load succeeded event w/ selected_lpm set
                let lastAnalytic = analyticsClient.events.last
                XCTAssertEqual(lastAnalytic?.event, .paymentSheetLoadSucceeded)
                XCTAssertEqual(lastAnalytic?.params["selected_lpm"] as? String, "card")
                loaded.fulfill()
            case .failure(let error):
                XCTFail(error.nonGenericDescription)
            }
        }
        wait(for: [loaded], timeout: 2)
    }

    func testReturningCustomerWithCardAndUSBankAccount_onlyCards() throws {
        StubbedBackend.stubPaymentMethods(fileMock: .saved_payment_methods_withCard_200, pmType: "card")
        StubbedBackend.stubPaymentMethods(fileMock: .saved_payment_methods_withUSBank_200, pmType: "us_bank_account")
        StubbedBackend.stubPaymentMethods(fileMock: .saved_payment_methods_200, pmType: "sepa_debit")
        StubbedBackend.stubSessions(paymentMethods: "\"card\"")

        let configuration = self.configuration(apiClient: stubbedAPIClient())
        let loaded = expectation(description: "Loaded")
        PaymentSheetLoader.load(
            mode: .paymentIntentClientSecret("pi_12345_secret_54321"),
            configuration: configuration,
            analyticsHelper: .init(integrationShape: .flowController, configuration: configuration),
            integrationShape: .flowController
        ) { result in
            switch result {
            case .success(let loadResult):
                guard case .paymentIntent(let paymentIntent) = loadResult.intent else {
                    XCTFail("Expecting payment intent")
                    return
                }
                XCTAssertEqual(paymentIntent.stripeId, "pi_3Kth")
                XCTAssertEqual(loadResult.savedPaymentMethods.count, 1)
                XCTAssertEqual(loadResult.savedPaymentMethods[0].type, .card)
                loaded.fulfill()
            case .failure(let error):
                XCTFail(error.nonGenericDescription)

            }
        }
        wait(for: [loaded], timeout: 2)
    }

    func testReturningCustomerWithCardAndUSBankAccount() throws {
        StubbedBackend.stubPaymentMethods(fileMock: .saved_payment_methods_withCard_200, pmType: "card")
        StubbedBackend.stubPaymentMethods(fileMock: .saved_payment_methods_withUSBank_200, pmType: "us_bank_account")
        StubbedBackend.stubPaymentMethods(fileMock: .saved_payment_methods_200, pmType: "sepa_debit")
        StubbedBackend.stubSessions(paymentMethods: "\"card\", \"us_bank_account\"")
        let configuration = self.configuration(apiClient: stubbedAPIClient())

        let loaded = expectation(description: "Loaded")
        PaymentSheetLoader.load(
            mode: .paymentIntentClientSecret("pi_12345_secret_54321"),
            configuration: configuration,
            analyticsHelper: .init(integrationShape: .flowController, configuration: configuration),
            integrationShape: .flowController
        ) { result in
            switch result {
            case .success(let loadResult):
                guard case .paymentIntent(let paymentIntent) = loadResult.intent else {
                    XCTFail("Expecting payment intent")
                    return
                }
                XCTAssertEqual(paymentIntent.stripeId, "pi_3Kth")
                XCTAssertEqual(loadResult.savedPaymentMethods.count, 2)
                XCTAssertEqual(loadResult.savedPaymentMethods[0].type, .card)
                XCTAssertEqual(loadResult.savedPaymentMethods[1].type, .USBankAccount)

                loaded.fulfill()
            case .failure(let error):
                XCTFail(error.nonGenericDescription)
            }
        }
        wait(for: [loaded], timeout: 2)
    }

    func testPaymentSheetLoadPaymentIntentFallback() {
        // If v1/elements/session fails to load...
        stub { urlRequest in
            return urlRequest.url?.absoluteString.contains("/v1/elements/sessions") ?? false
        } response: { _ in
            return HTTPStubsResponse(data: Data(), statusCode: 500, headers: nil)
        }
        // ...and /v1/payment_intents succeeds...
        stub { urlRequest in
            return urlRequest.url?.absoluteString.contains("/v1/payment_intents") ?? false
        } response: { _ in
            return HTTPStubsResponse(data: try! FileMock.payment_intents_200.data(), statusCode: 200, headers: nil)
        }
        // ...and the customer has payment methods...
        StubbedBackend.stubPaymentMethods(fileMock: .saved_payment_methods_withCard_200, pmType: "card")
        StubbedBackend.stubPaymentMethods(fileMock: .saved_payment_methods_200, pmType: "us_bank_account")
        StubbedBackend.stubPaymentMethods(fileMock: .saved_payment_methods_200, pmType: "sepa_debit")

        // ...loading PaymentSheet with a customer...
        let loaded = expectation(description: "Loaded")
        let configuration = self.configuration(apiClient: stubbedAPIClient())
        let analyticsClient = STPTestingAnalyticsClient()
        PaymentSheetLoader.load(
            mode: .paymentIntentClientSecret("pi_1234_secret_1234"),
            configuration: configuration,
            analyticsHelper: .init(integrationShape: .complete, configuration: configuration, analyticsClient: analyticsClient),
            integrationShape: .complete
        ) { result in
            loaded.fulfill()
            switch result {
            case .success(let loadResult):
                // ...should still succeed...
                guard case let .paymentIntent(paymentIntent) = loadResult.intent else {
                    XCTFail()
                    return
                }

                // ...with an ElementsSession whose payment method types is equal to the PaymentIntent...
                XCTAssertEqual(
                    paymentIntent.paymentMethodTypes.map { STPPaymentMethodType(rawValue: $0.intValue) },
                    loadResult.elementsSession.orderedPaymentMethodTypes
                )

                // ...and with the customer's payment methods
                XCTAssertEqual(loadResult.savedPaymentMethods.count, 1)

                // ...and with link disabled
                XCTAssertFalse(PaymentSheet.isLinkEnabled(elementsSession: loadResult.elementsSession, configuration: configuration))

                // ...and apple pay enabled
                XCTAssertTrue(PaymentSheet.isApplePayEnabled(elementsSession: loadResult.elementsSession, configuration: configuration))

                // ...and should report analytics indicating the v1/elements/session load failed
                let analyticEvents = analyticsClient.events.map { $0.event }
                XCTAssertEqual(analyticEvents, [.paymentSheetLoadStarted, .paymentSheetElementsSessionLoadFailed, .paymentSheetLoadSucceeded])
            case .failure(let error):
                XCTFail(error.nonGenericDescription)
            }
        }
        wait(for: [loaded], timeout: 10)
    }

    func testPaymentSheetLoadSetupIntentFallback() {
        // If v1/elements/session fails to load...
        stub { urlRequest in
            return urlRequest.url?.absoluteString.contains("/v1/elements/sessions") ?? false
        } response: { _ in
            return HTTPStubsResponse(data: Data(), statusCode: 500, headers: nil)
        }
        // ...and /v1/setup_intents succeeds...
        stub { urlRequest in
            return urlRequest.url?.absoluteString.contains("/v1/setup_intents") ?? false
        } response: { _ in
            return HTTPStubsResponse(data: try! FileMock.setup_intents_200.data(), statusCode: 200, headers: nil)
        }
        // ...and the customer has payment methods...
        StubbedBackend.stubPaymentMethods(fileMock: .saved_payment_methods_withCard_200, pmType: "card")
        StubbedBackend.stubPaymentMethods(fileMock: .saved_payment_methods_200, pmType: "us_bank_account")
        StubbedBackend.stubPaymentMethods(fileMock: .saved_payment_methods_200, pmType: "sepa_debit")

        // ...loading PaymentSheet with a customer...
        let loaded = expectation(description: "Loaded")
        let analyticsClient = STPTestingAnalyticsClient()
        let configuration = self.configuration(apiClient: stubbedAPIClient())
        PaymentSheetLoader.load(
            mode: .setupIntentClientSecret("seti_1234_secret_1234"),
            configuration: configuration,
            analyticsHelper: .init(integrationShape: .complete, configuration: configuration, analyticsClient: analyticsClient),
            integrationShape: .complete
        ) { result in
            loaded.fulfill()
            switch result {
            case .success(let loadResult):
                // ...should still succeed...
                guard case let .setupIntent(setupIntent) = loadResult.intent else {
                    XCTFail()
                    return
                }

                // ...with an ElementsSession whose payment method types is equal to the SetupIntent...
                XCTAssertEqual(
                    setupIntent.paymentMethodTypes.map { STPPaymentMethodType(rawValue: $0.intValue) },
                    loadResult.elementsSession.orderedPaymentMethodTypes
                )

                // ...and with the customer's payment methods
                XCTAssertEqual(loadResult.savedPaymentMethods.count, 1)

                // ...and with link disabled
                XCTAssertFalse(PaymentSheet.isLinkEnabled(elementsSession: loadResult.elementsSession, configuration: configuration))

                // ...and apple pay enabled
                XCTAssertTrue(PaymentSheet.isApplePayEnabled(elementsSession: loadResult.elementsSession, configuration: configuration))

                // ...and should report analytics indicating the v1/elements/session load failed
                let analyticEvents = analyticsClient.events.map { $0.event }
                XCTAssertEqual(analyticEvents, [.paymentSheetLoadStarted, .paymentSheetElementsSessionLoadFailed, .paymentSheetLoadSucceeded])
            case .failure(let error):
                XCTFail(error.nonGenericDescription)
            }
        }
        wait(for: [loaded], timeout: 10)
    }

    func testPaymentSheetLoadDeferredFallback() {
        // If v1/elements/session fails to load...
        stub { urlRequest in
            return urlRequest.url?.absoluteString.contains("/v1/elements/sessions") ?? false
        } response: { _ in
            return HTTPStubsResponse(data: Data(), statusCode: 500, headers: nil)
        }

        // ...and we're using a deferred intent without PM types specified...
        var intentConfig = PaymentSheet.IntentConfiguration(mode: .payment(amount: 100, currency: "usd"), confirmHandler: { _, _, _ in })

        // ...and the customer has payment methods...
        StubbedBackend.stubPaymentMethods(fileMock: .saved_payment_methods_withCard_200, pmType: "card")
        StubbedBackend.stubPaymentMethods(fileMock: .saved_payment_methods_200, pmType: "us_bank_account")
        StubbedBackend.stubPaymentMethods(fileMock: .saved_payment_methods_200, pmType: "sepa_debit")

        // ...loading PaymentSheet with a customer...
        let loaded = expectation(description: "LoadedWithoutTypes")
        let configuration = self.configuration(apiClient: stubbedAPIClient())
        let analyticsClient = STPTestingAnalyticsClient()
        PaymentSheetLoader.load(
            mode: .deferredIntent(intentConfig),
            configuration: configuration,
            analyticsHelper: .init(integrationShape: .complete, configuration: configuration, analyticsClient: analyticsClient),
            integrationShape: .complete
        ) { result in
            loaded.fulfill()
            switch result {
            case .success(let loadResult):
                // ...should still succeed...
                guard case .deferredIntent = loadResult.intent else {
                    XCTFail()
                    return
                }

                // ...with an ElementsSession whose payment method types is just [.card]
                XCTAssertEqual(
                    [.card],
                    loadResult.elementsSession.orderedPaymentMethodTypes
                )

                // ...and with the customer's payment methods
                XCTAssertEqual(loadResult.savedPaymentMethods.count, 1)

                // ...and with link disabled
                XCTAssertFalse(PaymentSheet.isLinkEnabled(elementsSession: loadResult.elementsSession, configuration: configuration))

                // ...and apple pay enabled
                XCTAssertTrue(PaymentSheet.isApplePayEnabled(elementsSession: loadResult.elementsSession, configuration: configuration))

                // ...and should report analytics indicating the v1/elements/session load failed
                let analyticEvents = analyticsClient.events.map { $0.event }
                XCTAssertEqual(analyticEvents, [.paymentSheetLoadStarted, .paymentSheetElementsSessionLoadFailed, .paymentSheetLoadSucceeded])
            case .failure(let error):
                XCTFail(error.nonGenericDescription)
            }
        }
        wait(for: [loaded], timeout: 2)
        analyticsClient.events = []

        // Doing the same load as above, but with an IntentConfig that specifies payment method types...
        intentConfig.paymentMethodTypes = ["card", "klarna"]
        let loaded2 = expectation(description: "LoadedWithTypes")
        PaymentSheetLoader.load(
            mode: .deferredIntent(intentConfig),
            configuration: configuration,
            analyticsHelper: .init(integrationShape: .complete, configuration: configuration, analyticsClient: analyticsClient),
            integrationShape: .complete
        ) { result in
            loaded2.fulfill()
            switch result {
            case .success(let loadResult):
                // ...should still succeed...
                guard case .deferredIntent = loadResult.intent else {
                    XCTFail()
                    return
                }

                // ...with an ElementsSession whose payment method types matches the intent config
                XCTAssertEqual(
                    [.card, .klarna],
                    loadResult.elementsSession.orderedPaymentMethodTypes
                )

                // ...and with the customer's payment methods
                XCTAssertEqual(loadResult.savedPaymentMethods.count, 1)

                // ...and with link disabled
                XCTAssertFalse(PaymentSheet.isLinkEnabled(elementsSession: loadResult.elementsSession, configuration: configuration))

                // ...and apple pay enabled
                XCTAssertTrue(PaymentSheet.isApplePayEnabled(elementsSession: loadResult.elementsSession, configuration: configuration))

                // ...and should report analytics indicating the v1/elements/session load failed
                let analyticEvents = analyticsClient.events.map { $0.event }
                XCTAssertEqual(analyticEvents, [.paymentSheetLoadStarted, .paymentSheetElementsSessionLoadFailed, .paymentSheetLoadSucceeded])
            case .failure(let error):
                XCTFail(error.nonGenericDescription)
            }
        }
        wait(for: [loaded2], timeout: 2)
    }

    func testSendsErrorAnalytic() {
        let analyticsClient = STPAnalyticsClient()
        stub { urlRequest in
            return urlRequest.url?.absoluteString.contains("/v1/elements/sessions") ?? false
        } response: { _ in
            let notConnectedError = NSError(domain: NSURLErrorDomain, code: URLError.notConnectedToInternet.rawValue)
            return HTTPStubsResponse(error: notConnectedError)
        }

        let loadExpectation = XCTestExpectation(description: "Load PaymentSheet")
        // Test PaymentSheetLoader.load can load various IntentConfigurations
        let confirmHandler: PaymentSheet.IntentConfiguration.ConfirmHandler = {_, _, _ in
            XCTFail("Confirm handler shouldn't be called.")
        }
        let intentConfig = PaymentSheet.IntentConfiguration.init(mode: .payment(amount: 100, currency: "USD"), confirmHandler: confirmHandler)
        PaymentSheetLoader.load(
            mode: .deferredIntent(intentConfig),
            configuration: PaymentSheet.Configuration._testValue_MostPermissive(),
            analyticsHelper: .init(integrationShape: .complete, configuration: PaymentSheet.Configuration._testValue_MostPermissive(), analyticsClient: analyticsClient),
            integrationShape: .complete
        ) { result in
            loadExpectation.fulfill()
            switch result {
            case .success:
                XCTFail("Test case successfully loaded but it should have failed.")
            case .failure:
                break
            }
            // Should send a load failure analytic
            let analyticEvent = analyticsClient._testLogHistory.last
            XCTAssertEqual(analyticEvent?["event"] as? String, STPAnalyticEvent.paymentSheetLoadFailed.rawValue)
            XCTAssertEqual(analyticEvent?["error_type"] as? String, "NSURLErrorDomain")
            XCTAssertEqual(analyticEvent?["error_code"] as? String, "-1009")
        }
        wait(for: [loadExpectation], timeout: STPTestingNetworkRequestTimeout)
    }
}
