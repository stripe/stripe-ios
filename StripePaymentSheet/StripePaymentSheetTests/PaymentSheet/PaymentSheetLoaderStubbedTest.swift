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
        return config
    }

    func testReturningCustomerWithNoSavedCards() throws {
        StubbedBackend.stubPaymentMethods(fileMock: .saved_payment_methods_200, pmType: "card")
        StubbedBackend.stubPaymentMethods(fileMock: .saved_payment_methods_200, pmType: "us_bank_account")
        StubbedBackend.stubPaymentMethods(fileMock: .saved_payment_methods_200, pmType: "sepa_debit")
        StubbedBackend.stubSessions(paymentMethods: "\"card\", \"us_bank_account\"")

        let loaded = expectation(description: "Loaded")
        PaymentSheetLoader.load(
            mode: .paymentIntentClientSecret("pi_12345_secret_54321"),
            configuration: self.configuration(apiClient: stubbedAPIClient())
        ) { result in
            switch result {
            case .success(let intent, let paymentMethods, _):
                guard case .paymentIntent(_, let setupIntent) = intent else {
                    XCTFail("Expecting payment intent")
                    return
                }
                XCTAssertEqual(setupIntent.stripeId, "pi_3Kth")
                XCTAssertEqual(paymentMethods.count, 0)
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
        PaymentSheetLoader.load(
            mode: .paymentIntentClientSecret("pi_12345_secret_54321"),
            configuration: self.configuration(apiClient: stubbedAPIClient())
        ) { result in
            switch result {
            case .success(let intent, let paymentMethods, _):
                guard case .paymentIntent(_, let setupIntent) = intent else {
                    XCTFail("Expecting payment intent")
                    return
                }
                XCTAssertEqual(setupIntent.stripeId, "pi_3Kth")
                XCTAssertEqual(paymentMethods.count, 1)
                XCTAssertEqual(paymentMethods[0].type, .card)
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

        let loaded = expectation(description: "Loaded")
        PaymentSheetLoader.load(
            mode: .paymentIntentClientSecret("pi_12345_secret_54321"),
            configuration: self.configuration(apiClient: stubbedAPIClient())
        ) { result in
            switch result {
            case .success(let intent, let paymentMethods, _):
                guard case .paymentIntent(_, let setupIntent) = intent else {
                    XCTFail("Expecting payment intent")
                    return
                }
                XCTAssertEqual(setupIntent.stripeId, "pi_3Kth")
                XCTAssertEqual(paymentMethods.count, 1)
                XCTAssertEqual(paymentMethods[0].type, .card)
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

        let loaded = expectation(description: "Loaded")
        PaymentSheetLoader.load(
            mode: .paymentIntentClientSecret("pi_12345_secret_54321"),
            configuration: self.configuration(apiClient: stubbedAPIClient())
        ) { result in
            switch result {
            case .success(let intent, let paymentMethods, _):
                guard case .paymentIntent(_, let setupIntent) = intent else {
                    XCTFail("Expecting payment intent")
                    return
                }
                XCTAssertEqual(setupIntent.stripeId, "pi_3Kth")
                XCTAssertEqual(paymentMethods.count, 2)
                XCTAssertEqual(paymentMethods[0].type, .card)
                XCTAssertEqual(paymentMethods[1].type, .USBankAccount)

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
        let analyticsClient = STPTestingAnalyticsClient()
        PaymentSheetLoader.load(
            mode: .paymentIntentClientSecret("pi_1234_secret_1234"),
            configuration: self.configuration(apiClient: stubbedAPIClient()),
            analyticsClient: analyticsClient
        ) { result in
            loaded.fulfill()
            switch result {
            case let .success(intent, paymentMethods, isLinkEnabled):
                // ...should still succeed...
                guard case let .paymentIntent(elementsSession, paymentIntent) = intent else {
                    XCTFail()
                    return
                }

                // ...with an ElementsSession whose payment method types is equal to the PaymentIntent...
                XCTAssertEqual(
                    paymentIntent.paymentMethodTypes.map { STPPaymentMethodType(rawValue: $0.intValue) },
                    elementsSession.orderedPaymentMethodTypes
                )

                // ...and with the customer's payment methods
                XCTAssertEqual(paymentMethods.count, 1)

                // ...and with link disabled
                XCTAssertFalse(isLinkEnabled)

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
        PaymentSheetLoader.load(
            mode: .setupIntentClientSecret("seti_1234_secret_1234"),
            configuration: self.configuration(apiClient: stubbedAPIClient()),
            analyticsClient: analyticsClient
        ) { result in
            loaded.fulfill()
            switch result {
            case let .success(intent, paymentMethods, isLinkEnabled):
                // ...should still succeed...
                guard case let .setupIntent(elementsSession, setupIntent) = intent else {
                    XCTFail()
                    return
                }

                // ...with an ElementsSession whose payment method types is equal to the SetupIntent...
                XCTAssertEqual(
                    setupIntent.paymentMethodTypes.map { STPPaymentMethodType(rawValue: $0.intValue) },
                    elementsSession.orderedPaymentMethodTypes
                )

                // ...and with the customer's payment methods
                XCTAssertEqual(paymentMethods.count, 1)

                // ...and with link disabled
                XCTAssertFalse(isLinkEnabled)

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
        let analyticsClient = STPTestingAnalyticsClient()
        PaymentSheetLoader.load(
            mode: .deferredIntent(intentConfig),
            configuration: self.configuration(apiClient: stubbedAPIClient()),
            analyticsClient: analyticsClient
        ) { result in
            loaded.fulfill()
            switch result {
            case let .success(intent, paymentMethods, isLinkEnabled):
                // ...should still succeed...
                guard case let .deferredIntent(elementsSession, _) = intent else {
                    XCTFail()
                    return
                }

                // ...with an ElementsSession whose payment method types is just [.card]
                XCTAssertEqual(
                    [.card],
                    elementsSession.orderedPaymentMethodTypes
                )

                // ...and with the customer's payment methods
                XCTAssertEqual(paymentMethods.count, 1)

                // ...and with link disabled
                XCTAssertFalse(isLinkEnabled)

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
            configuration: self.configuration(apiClient: stubbedAPIClient()),
            analyticsClient: analyticsClient
        ) { result in
            loaded2.fulfill()
            switch result {
            case let .success(intent, paymentMethods, isLinkEnabled):
                // ...should still succeed...
                guard case let .deferredIntent(elementsSession, _) = intent else {
                    XCTFail()
                    return
                }

                // ...with an ElementsSession whose payment method types matches the intent config
                XCTAssertEqual(
                    [.card, .klarna],
                    elementsSession.orderedPaymentMethodTypes
                )

                // ...and with the customer's payment methods
                XCTAssertEqual(paymentMethods.count, 1)

                // ...and with link disabled
                XCTAssertFalse(isLinkEnabled)

                // ...and should report analytics indicating the v1/elements/session load failed
                let analyticEvents = analyticsClient.events.map { $0.event }
                XCTAssertEqual(analyticEvents, [.paymentSheetLoadStarted, .paymentSheetElementsSessionLoadFailed, .paymentSheetLoadSucceeded])
            case .failure(let error):
                XCTFail(error.nonGenericDescription)
            }
        }
        wait(for: [loaded2], timeout: 2)
    }
}
