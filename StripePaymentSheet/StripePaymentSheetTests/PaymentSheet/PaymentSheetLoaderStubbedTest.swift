//
//  PaymentSheetLoaderMockedTest.swift
//  StripePaymentSheetTests
//

@testable @_spi(STP) import StripePaymentSheet

import OHHTTPStubs
import OHHTTPStubsSwift
@_spi(STP) @testable import StripeCore
@_spi(STP) import StripeCoreTestUtils
import StripePaymentsObjcTestUtils
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
        StubbedBackend.stubPaymentMethods(paymentMethodTypes: [])
        StubbedBackend.stubSessions(paymentMethods: "\"card\", \"us_bank_account\"")
        StubbedBackend.stubCustomers()
        StubbedBackend.stubLookup()

        let loaded = expectation(description: "Loaded")
        let analyticsClient = STPTestingAnalyticsClient()
        var configuration = self.configuration(apiClient: stubbedAPIClient())
        configuration.applePay = nil

        PaymentSheetLoader.load(
            mode: .paymentIntentClientSecret("pi_12345_secret_54321"),
            configuration: configuration,
            analyticsHelper: ._testValue(
                integrationShape: .flowController,
                configuration: configuration,
                analyticsClient: analyticsClient
            ),
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
        StubbedBackend.stubPaymentMethods(paymentMethodTypes: [.card])
        StubbedBackend.stubSessions(paymentMethods: "\"card\", \"us_bank_account\"")
        StubbedBackend.stubCustomers()
        StubbedBackend.stubLookup()

        let loaded = expectation(description: "Loaded")
        let analyticsClient = STPTestingAnalyticsClient()
        var configuration = self.configuration(apiClient: stubbedAPIClient())
        configuration.applePay = nil
        PaymentSheetLoader.load(
            mode: .paymentIntentClientSecret("pi_12345_secret_54321"),
            configuration: configuration,
            analyticsHelper: ._testValue(
                integrationShape: .flowController,
                configuration: configuration,
                analyticsClient: analyticsClient
            ),
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
        StubbedBackend.stubPaymentMethods(paymentMethodTypes: [.card, .USBankAccount])
        StubbedBackend.stubSessions(paymentMethods: "\"card\"")
        StubbedBackend.stubCustomers()
        StubbedBackend.stubLookup()

        let configuration = self.configuration(apiClient: stubbedAPIClient())
        let loaded = expectation(description: "Loaded")
        PaymentSheetLoader.load(
            mode: .paymentIntentClientSecret("pi_12345_secret_54321"),
            configuration: configuration,
            analyticsHelper: ._testValue(integrationShape: .flowController),
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
        StubbedBackend.stubPaymentMethods(paymentMethodTypes: [.card, .USBankAccount])
        StubbedBackend.stubSessions(paymentMethods: "\"card\", \"us_bank_account\"")
        StubbedBackend.stubCustomers()
        StubbedBackend.stubLookup()
        let configuration = self.configuration(apiClient: stubbedAPIClient())

        let loaded = expectation(description: "Loaded")
        PaymentSheetLoader.load(
            mode: .paymentIntentClientSecret("pi_12345_secret_54321"),
            configuration: configuration,
            analyticsHelper: ._testValue(integrationShape: .flowController, configuration: configuration),
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
                XCTAssertEqual(loadResult.savedPaymentMethods[0].type, .USBankAccount)
                XCTAssertEqual(loadResult.savedPaymentMethods[1].type, .card)

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
        StubbedBackend.stubPaymentMethods(paymentMethodTypes: [.card])
        StubbedBackend.stubCustomers()
        StubbedBackend.stubLookup()

        // ...loading PaymentSheet with a customer...
        let loaded = expectation(description: "Loaded")
        let configuration = self.configuration(apiClient: stubbedAPIClient())
        let analyticsClient = STPTestingAnalyticsClient()
        PaymentSheetLoader.load(
            mode: .paymentIntentClientSecret("pi_1234_secret_1234"),
            configuration: configuration,
            analyticsHelper: ._testValue(configuration: configuration, analyticsClient: analyticsClient),
            integrationShape: .paymentSheet
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
                    paymentIntent.paymentMethodTypes,
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

    func testPaymentSheetLoadPaymentIntentFallbackCardPrioritization() {
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
            return HTTPStubsResponse(data: try! FileMock.payment_intents_misordered_pms_200.data(), statusCode: 200, headers: nil)
        }
        StubbedBackend.stubPaymentMethods(paymentMethodTypes: [])
        StubbedBackend.stubCustomers()
        StubbedBackend.stubLookup()

        // ...loading PaymentSheet with a customer...
        let loaded = expectation(description: "Loaded")
        let configuration = self.configuration(apiClient: stubbedAPIClient())
        let analyticsClient = STPTestingAnalyticsClient()
        PaymentSheetLoader.load(
            mode: .paymentIntentClientSecret("pi_1234_secret_1234"),
            configuration: configuration,
            analyticsHelper: ._testValue(configuration: configuration, analyticsClient: analyticsClient),
            integrationShape: .paymentSheet
        ) { result in
            loaded.fulfill()
            switch result {
            case .success(let loadResult):
                // ...should still succeed...
                guard case let .paymentIntent(paymentIntent) = loadResult.intent else {
                    XCTFail()
                    return
                }

                // ...with an ElementsSession whose payment method types contain the same as the PaymentIntent...
                XCTAssertEqual(
                    Set(paymentIntent.paymentMethodTypes.map { $0 }),
                    Set(loadResult.elementsSession.orderedPaymentMethodTypes)
                )

                // and with card listed first
                XCTAssert(loadResult.elementsSession.orderedPaymentMethodTypes.first == .card)
            case .failure(let error):
                XCTFail(error.nonGenericDescription)
            }
        }
        wait(for: [loaded], timeout: 10)
    }

    func testPaymentSheetLoadPaymentIntentFallbackNoCard() {
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
            return HTTPStubsResponse(data: try! FileMock.payment_intents_no_card_200.data(), statusCode: 200, headers: nil)
        }
        StubbedBackend.stubPaymentMethods(paymentMethodTypes: [])
        StubbedBackend.stubCustomers()
        StubbedBackend.stubLookup()

        // ...loading PaymentSheet with a customer...
        let loaded = expectation(description: "Loaded")
        let configuration = self.configuration(apiClient: stubbedAPIClient())
        let analyticsClient = STPTestingAnalyticsClient()
        PaymentSheetLoader.load(
            mode: .paymentIntentClientSecret("pi_1234_secret_1234"),
            configuration: configuration,
            analyticsHelper: ._testValue(configuration: configuration, analyticsClient: analyticsClient),
            integrationShape: .paymentSheet
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
                    paymentIntent.paymentMethodTypes.map { $0 },
                    loadResult.elementsSession.orderedPaymentMethodTypes
                )
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
        StubbedBackend.stubPaymentMethods(paymentMethodTypes: [.card])
        StubbedBackend.stubCustomers()
        StubbedBackend.stubLookup()

        // ...loading PaymentSheet with a customer...
        let loaded = expectation(description: "Loaded")
        let analyticsClient = STPTestingAnalyticsClient()
        let configuration = self.configuration(apiClient: stubbedAPIClient())
        PaymentSheetLoader.load(
            mode: .setupIntentClientSecret("seti_1234_secret_1234"),
            configuration: configuration,
            analyticsHelper: ._testValue(configuration: configuration, analyticsClient: analyticsClient),
            integrationShape: .paymentSheet
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
                    setupIntent.paymentMethodTypes,
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
        var intentConfig = PaymentSheet.IntentConfiguration(mode: .payment(amount: 100, currency: "usd"), confirmHandler: { _, _ in return "" })

        // ...and the customer has payment methods...
        StubbedBackend.stubPaymentMethods(paymentMethodTypes: [.card])
        StubbedBackend.stubCustomers()
        StubbedBackend.stubLookup()

        // ...loading PaymentSheet with a customer...
        let loaded = expectation(description: "LoadedWithoutTypes")
        let configuration = self.configuration(apiClient: stubbedAPIClient())
        let analyticsClient = STPTestingAnalyticsClient()
        PaymentSheetLoader.load(
            mode: .deferredIntent(intentConfig),
            configuration: configuration,
            analyticsHelper: ._testValue(configuration: configuration, analyticsClient: analyticsClient),
            integrationShape: .paymentSheet
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
            analyticsHelper: ._testValue(configuration: configuration, analyticsClient: analyticsClient),
            integrationShape: .paymentSheet
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

    func testCheckoutSessionWithCustomerConfigurationThrowsError() {
        let json = STPTestUtils.jsonNamed("CheckoutSession")!
        let checkoutSession = STPCheckoutSession.decodedObject(fromAPIResponse: json)!

        var configuration = PaymentSheet.Configuration()
        configuration.apiClient = stubbedAPIClient()
        configuration.customer = PaymentSheet.CustomerConfiguration(id: "cus_123", ephemeralKeySecret: "ek_456")

        let loaded = expectation(description: "Loaded")
        STPAssertTestUtil.shouldSuppressNextSTPAlert = true
        PaymentSheetLoader.load(
            mode: .checkoutSession(checkoutSession),
            configuration: configuration,
            analyticsHelper: ._testValue(integrationShape: .complete),
            integrationShape: .paymentSheet
        ) { result in
            switch result {
            case .success:
                XCTFail("Expected failure when customer is set with CheckoutSession mode")
            case .failure(let error):
                guard case PaymentSheetError.integrationError = error else {
                    XCTFail("Expected PaymentSheetError.integrationError, got \(error)")
                    return
                }
            }
            loaded.fulfill()
        }
        wait(for: [loaded], timeout: 2)
    }

    func testCheckoutSessionWithoutEmailThrowsError() {
        var json = STPTestUtils.jsonNamed("CheckoutSession")!
        json["customer_email"] = NSNull()
        let checkoutSession = STPCheckoutSession.decodedObject(fromAPIResponse: json)!

        var configuration = PaymentSheet.Configuration()
        configuration.apiClient = stubbedAPIClient()

        let loaded = expectation(description: "Loaded")
        STPAssertTestUtil.shouldSuppressNextSTPAlert = true
        PaymentSheetLoader.load(
            mode: .checkoutSession(checkoutSession),
            configuration: configuration,
            analyticsHelper: ._testValue(integrationShape: .complete),
            integrationShape: .paymentSheet
        ) { result in
            switch result {
            case .success:
                XCTFail("Expected failure when email is not set with CheckoutSession mode")
            case .failure(let error):
                guard case PaymentSheetError.integrationError = error else {
                    XCTFail("Expected PaymentSheetError.integrationError, got \(error)")
                    return
                }
            }
            loaded.fulfill()
        }
        wait(for: [loaded], timeout: 2)
    }

    func testSendsErrorAnalytic() {
        // If v1/elements/session and the fallback fail to load...
        let analyticsClient = STPAnalyticsClient()
        stub { urlRequest in
            return urlRequest.url?.absoluteString.contains("/v1/elements/sessions") ?? false
        } response: { _ in
            let notConnectedError = NSError(domain: NSURLErrorDomain, code: URLError.notConnectedToInternet.rawValue)
            return HTTPStubsResponse(error: notConnectedError)
        }

        let loadExpectation = XCTestExpectation(description: "Load PaymentSheet")
        // Test PaymentSheetLoader.load can load various IntentConfigurations
        let confirmHandler: PaymentSheet.IntentConfiguration.ConfirmHandler = {_, _ in
            XCTFail("Confirm handler shouldn't be called.")
            return ""
        }
        let intentConfig = PaymentSheet.IntentConfiguration.init(mode: .payment(amount: 100, currency: "USD"), confirmHandler: confirmHandler)
        PaymentSheetLoader.load(
            mode: .deferredIntent(intentConfig),
            configuration: PaymentSheet.Configuration._testValue_MostPermissive(),
            analyticsHelper: ._testValue(configuration: PaymentSheet.Configuration._testValue_MostPermissive(), analyticsClient: analyticsClient),
            integrationShape: .paymentSheet
        ) { result in
            loadExpectation.fulfill()
            switch result {
            case .success:
                XCTFail("Test case successfully loaded but it should have failed.")
            case .failure:
                break
            }
            // ...we should send a load failure analytic
            let analyticEvent = analyticsClient._testLogHistory.last
            XCTAssertEqual(analyticEvent?["event"] as? String, STPAnalyticEvent.paymentSheetLoadFailed.rawValue)
            XCTAssertEqual(analyticEvent?["error_type"] as? String, "NSURLErrorDomain")
            XCTAssertEqual(analyticEvent?["error_code"] as? String, "-1009")
        }
        wait(for: [loadExpectation], timeout: STPTestingNetworkRequestTimeout)
    }

    // MARK: - `PaymentSheetLoader.lookupLinkAccount` unit tests

    @MainActor
    private func assertLinkLookup(
        experimentAssignments: [String: ExperimentGroup]?,
        flags: [String: Bool] = [:],
        shouldCallLookup: Bool,
        message: String
    ) async throws {
        var didCallLookup = false
        stub { urlRequest in
            if urlRequest.url?.absoluteString.contains("consumers/sessions/lookup") == true {
                didCallLookup = true
                return true
            }
            return false
        } response: { _ in
            return HTTPStubsResponse(data: try! FileMock.consumers_lookup_200.data(), statusCode: 200, headers: nil)
        }

        let experimentsData = experimentAssignments.map {
            ExperimentsData(arbId: "test_arb", experimentAssignments: $0, allResponseFields: [:])
        }
        let elementsSession = STPElementsSession._testValue(
            experimentsData: experimentsData,
            flags: flags
        )

        var config = PaymentSheet.Configuration()
        config.apiClient = stubbedAPIClient()
        config.defaultBillingDetails.email = "test@example.com"

        _ = try await PaymentSheetLoader.lookupLinkAccount(
            elementsSession: elementsSession,
            configuration: config,
            prefetchedEmailAndSource: nil,
            loadTimings: .init(),
            isUpdate: false
        )

        if shouldCallLookup {
            XCTAssertTrue(didCallLookup, message)
        } else {
            XCTAssertFalse(didCallLookup, message)
        }
    }

    func testLookupLink_linkDisabled_holdbackGlobal_shouldLookup() async throws {
        try await assertLinkLookup(
            experimentAssignments: ["link_global_holdback": .holdback],
            shouldCallLookup: true,
            message: "Expected Link lookup when link_global_holdback is 'holdback'"
        )
    }

    func testLookupLink_linkDisabled_holdbackABTest_shouldLookup() async throws {
        try await assertLinkLookup(
            experimentAssignments: ["link_ab_test": .holdback],
            shouldCallLookup: true,
            message: "Expected Link lookup when link_ab_test is 'holdback'"
        )
    }

    func testLookupLink_linkDisabled_bothExperimentsHoldback_shouldLookup() async throws {
        try await assertLinkLookup(
            experimentAssignments: [
                "link_global_holdback": .holdback,
                "link_ab_test": .holdback,
            ],
            shouldCallLookup: true,
            message: "Expected Link lookup when both experiments are 'holdback'"
        )
    }

    func testLookupLink_linkDisabled_holdbackWithKillswitch_shouldNotLookup() async throws {
        try await assertLinkLookup(
            experimentAssignments: ["link_global_holdback": .holdback],
            flags: ["elements_disable_link_global_holdback_lookup": true],
            shouldCallLookup: false,
            message: "Link lookup should not happen when killswitch is enabled"
        )
    }

    func testLookupLink_linkDisabled_noExperimentsData_shouldNotLookup() async throws {
        try await assertLinkLookup(
            experimentAssignments: nil,
            shouldCallLookup: false,
            message: "Link lookup should not happen when there is no experiments data"
        )
    }

    func testLookupLink_linkDisabled_controlGroup_shouldNotLookup() async throws {
        try await assertLinkLookup(
            experimentAssignments: ["link_global_holdback": .control],
            shouldCallLookup: false,
            message: "Link lookup should not happen when experiment is 'control' (not holdback)"
        )
    }

    // MARK: - Non-blocking Link Lookup + Experiment Logging

    func testLoad_linkDisabled_holdback_doesNotBlockOnLookup() throws {
        // Stub sessions with experiments_data injected into the response
        StubbedBackend.stubSessions(
            fileMock: .elementsSessionsPaymentMethod_200,
            responseCallback: { data in
                // First replace the payment method placeholders
                var mutated = StubbedBackend.updatePaymentMethodDetail(
                    data: data,
                    variables: [
                        "<paymentMethods>": "\"card\"",
                        "<currency>": "\"usd\"",
                    ]
                )
                // Inject experiments_data into the JSON
                var json = try! JSONSerialization.jsonObject(with: mutated) as! [String: Any]
                json["experiments_data"] = [
                    "arb_id": "test_arb_123",
                    "experiment_assignments": [
                        "link_global_holdback": "holdback",
                    ],
                ]
                mutated = try! JSONSerialization.data(withJSONObject: json)
                return mutated
            }
        )

        // Stub lookup with a 5-second delay
        stub { urlRequest in
            urlRequest.url?.absoluteString.contains("/v1/consumers/sessions/lookup") ?? false
        } response: { _ in
            let mockResponseData = try! FileMock.consumers_lookup_200.data()
            return HTTPStubsResponse(data: mockResponseData, statusCode: 200, headers: nil)
                .responseTime(0.3)
        }

        StubbedBackend.stubPaymentMethods(paymentMethodTypes: [])
        StubbedBackend.stubCustomers()

        let mockAnalyticsClientV2 = MockAnalyticsClientV2()
        var configuration = self.configuration(apiClient: stubbedAPIClient())
        configuration.defaultBillingDetails.email = "test@example.com"

        // load() should complete within 0.2s even though the Link Lookup takes 0.3: this validates lookup is non-blocking
        let loaded = expectation(description: "Loaded")
        PaymentSheetLoader.load(
            mode: .paymentIntentClientSecret("pi_12345_secret_54321"),
            configuration: configuration,
            analyticsHelper: ._testValue(
                integrationShape: .flowController,
                configuration: configuration,
                analyticsClientV2: mockAnalyticsClientV2
            ),
            integrationShape: .flowController
        ) { result in
            switch result {
            case .success:
                loaded.fulfill()
            case .failure(let error):
                XCTFail(error.nonGenericDescription)
            }
        }
        wait(for: [loaded], timeout: 0.2)

        // Experiment exposures are logged asynchronously after the lookup completes
        let predicate = NSPredicate { _, _ in
            mockAnalyticsClientV2.loggedAnalyticPayloads(withEventName: "elements.experiment_exposure").count >= 3
        }
        wait(for: [XCTNSPredicateExpectation(predicate: predicate, object: nil)], timeout: 5)

        // Verify the 3 exposure events
        let exposures = mockAnalyticsClientV2.loggedAnalyticPayloads(withEventName: "elements.experiment_exposure")
        XCTAssertEqual(exposures.count, 3)
        let experimentNames = Set(exposures.compactMap { $0["experiment_retrieved"] as? String })
        XCTAssertEqual(experimentNames, ["link_global_holdback", "link_global_holdback_aa", "link_ab_test"])
        for exposure in exposures {
            XCTAssertEqual(exposure["arb_id"] as? String, "test_arb_123")
            XCTAssertNotNil(exposure["assignment_group"], "Expected assignment_group in exposure: \(exposure)")
        }
    }
}
