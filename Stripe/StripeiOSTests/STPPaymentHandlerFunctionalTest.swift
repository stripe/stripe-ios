//
//  STPPaymentHandlerFunctionalTest.swift
//  StripeiOSTests
//
//  Created by Yuki Tokuhiro on 4/24/23.
//

@testable import Stripe
@_spi(STP) @testable import StripeCore
@_spi(STP) @testable import StripePayments
@_spi(STP) @testable import StripePaymentsTestUtils
import XCTest

// You can add tests in here for payment methods that don't require customer actions (i.e. don't open webviews for customer authentication).
// If they require customer action, use STPPaymentHandlerFunctionalTest.m instead
final class STPPaymentHandlerFunctionalSwiftTest: STPNetworkStubbingTestCase, STPAuthenticationContext {
    // MARK: - STPAuthenticationContext
    func authenticationPresentingViewController() -> UIViewController {
        return UIViewController()
    }

    // MARK: - PaymentIntent tests

    func test_card_payment_intent_server_side_confirmation() {
        let apiClient = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)
        let e = self.expectation(description: "")
        apiClient.createPaymentMethod(with: ._testValidCardValue()) { paymentMethod, error in
            guard let paymentMethod = paymentMethod else {
                XCTFail(String(describing: error))
                return
            }
            STPTestingAPIClient.shared().createPaymentIntent(withParams: [
                "confirm": "true",
                "payment_method_types": ["card"],
                "currency": "usd",
                "payment_method": paymentMethod.stripeId,
                "return_url": "foo://z",
            ]) { clientSecret, error in
                guard let clientSecret = clientSecret else {
                    XCTFail(String(describing: error))
                    return
                }
                let sut = STPPaymentHandler(apiClient: apiClient)
                // Note: `waitForExpectations` can deadlock if this test is async. When we can use Xcode 14.3, we can switch this test to async and use fulfillment(of:) instead of waitForExpectations
                sut.handleNextAction(forPayment: clientSecret, with: self, returnURL: "foo://z") { status, intent, _ in
                    XCTAssertEqual(sut.apiClient, apiClient) // Reference sut in the closure so it doesn't get deallocated
                    XCTAssertEqual(intent?.status, .succeeded)
                    XCTAssertEqual(status, .succeeded)
                    e.fulfill()
                }
            }
        }
        self.waitForExpectations(timeout: 10)
    }

    func test_sepa_debit_payment_intent_server_side_confirmation() {
        // SEPA Debit is a good payment method to test here because
        // - it's a "delayed" or "asynchronous" payment method
        // - it doesn't require customer actions (we can't simulate customer actions in XCTestCase)

        let apiClient = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)

        let billingDetails = STPPaymentMethodBillingDetails()
        billingDetails.name = "SEPA Test Customer"
        billingDetails.email = "test@example.com"

        let sepaDebitDetails = STPPaymentMethodSEPADebitParams()
        sepaDebitDetails.iban = "DE89370400440532013000"

        let e = self.expectation(description: "")
        apiClient.createPaymentMethod(with: .init(sepaDebit: sepaDebitDetails, billingDetails: billingDetails, metadata: nil)) { paymentMethod, error in
            guard let paymentMethod = paymentMethod else {
                XCTFail(String(describing: error))
                return
            }
            STPTestingAPIClient.shared().createPaymentIntent(withParams: [
                "confirm": "true",
                "payment_method_types": ["sepa_debit"],
                "currency": "eur",
                "payment_method": paymentMethod.stripeId,
                "return_url": "foo://z",
                "mandate_data": [
                    "customer_acceptance": [
                        "type": "online",
                        "online": [
                            "user_agent": "123",
                            "ip_address": "172.18.117.125",
                        ],
                    ],
                ],
            ]) { clientSecret, error in
                guard let clientSecret = clientSecret else {
                    XCTFail(String(describing: error))
                    return
                }
                let sut = STPPaymentHandler(apiClient: apiClient)
                // Note: `waitForExpectations` can deadlock if this test is async. When we can use Xcode 14.3, we can switch this test to async and use fulfillment(of:) instead of waitForExpectations
                sut.handleNextAction(forPayment: clientSecret, with: self, returnURL: "foo://z") { status, intent, _ in
                    XCTAssertEqual(sut.apiClient, apiClient) // Reference sut in the closure so it doesn't get deallocated
                    XCTAssertEqual(intent?.status, .processing)
                    XCTAssertEqual(status, .succeeded)
                    e.fulfill()
                }
            }
        }
        self.waitForExpectations(timeout: 10)
    }

    // MARK: - SetupIntent tests

    func test_card_setup_intent_server_side_confirmation() {
        let apiClient = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)

        let e = self.expectation(description: "")
        apiClient.createPaymentMethod(with: ._testValidCardValue()) { paymentMethod, error in
            guard let paymentMethod = paymentMethod else {
                XCTFail(String(describing: error))
                return
            }
            STPTestingAPIClient.shared().createSetupIntent(withParams: [
                "confirm": "true",
                "payment_method_types": ["card"],
                "payment_method": paymentMethod.stripeId,
                "return_url": "foo://z",
            ]) { clientSecret, error in
                guard let clientSecret = clientSecret else {
                    XCTFail(String(describing: error))
                    return
                }
                let sut = STPPaymentHandler(apiClient: apiClient)
                // Note: `waitForExpectations` can deadlock if this test is async. When we can use Xcode 14.3, we can switch this test to async and use fulfillment(of:) instead of waitForExpectations
                sut.handleNextAction(forSetupIntent: clientSecret, with: self, returnURL: "foo://z") { status, intent, _ in
                    XCTAssertEqual(sut.apiClient, apiClient) // Reference sut in the closure so it doesn't get deallocated
                    XCTAssertEqual(intent?.status, .succeeded)
                    XCTAssertEqual(status, .succeeded)
                    e.fulfill()
                }
            }
        }
        self.waitForExpectations(timeout: 10)
    }

    func test_sepa_debit_setup_intent_server_side_confirmation() {
        // SEPA Debit is a good payment method to test here because
        // - it's a "delayed" or "asynchronous" payment method
        // - it doesn't require customer actions (we can't simulate customer actions in XCTestCase)

        let apiClient = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)

        let billingDetails = STPPaymentMethodBillingDetails()
        billingDetails.name = "SEPA Test Customer"
        billingDetails.email = "test@example.com"

        let sepaDebitDetails = STPPaymentMethodSEPADebitParams()
        sepaDebitDetails.iban = "DE89370400440532013000"

        let e = self.expectation(description: "")
        apiClient.createPaymentMethod(with: .init(sepaDebit: sepaDebitDetails, billingDetails: billingDetails, metadata: nil)) { paymentMethod, error in
            guard let paymentMethod = paymentMethod else {
                XCTFail()
                return
            }
            STPTestingAPIClient.shared().createSetupIntent(withParams: [
                "confirm": "true",
                "payment_method_types": ["sepa_debit"],
                "payment_method": paymentMethod.stripeId,
                "return_url": "foo://z",
                "mandate_data": [
                    "customer_acceptance": [
                        "type": "online",
                        "online": [
                            "user_agent": "123",
                            "ip_address": "172.18.117.125",
                        ],
                    ],
                ],
            ]) { clientSecret, error in
                guard let clientSecret = clientSecret else {
                    XCTFail("\(String(describing: error))")
                    return
                }
                let sut = STPPaymentHandler(apiClient: apiClient)
                // Note: `waitForExpectations` can deadlock if this test is async. When we can use Xcode 14.3, we can switch this test to async and use fulfillment(of:) instead of waitForExpectations
                sut.handleNextAction(forSetupIntent: clientSecret, with: self, returnURL: "foo://z") { status, intent, _ in
                    XCTAssertEqual(sut.apiClient, apiClient) // Reference sut in the closure so it doesn't get deallocated
                    XCTAssertEqual(intent?.status, .succeeded) // Note: I think this should be .processing, but testmode disagrees
                    XCTAssertEqual(status, .succeeded)
                    e.fulfill()
                }
            }
        }
        self.waitForExpectations(timeout: 10)
    }

    // MARK: - Test payment handler sends analytics

    func test_confirm_payment_intent_sends_analytic() {
        // Confirming a hardcoded already-confirmed PI with invalid params...
        let paymentIntentParams = STPPaymentIntentParams(clientSecret: "pi_3P20wFFY0qyl6XeW0dSOQ6W7_secret_9V8GkrCOt1MEW8SBmAaGnmT6A", paymentMethodType: .card)
        let paymentHandlerExpectation = expectation(description: "paymentHandlerExpectation")
        let paymentHandler = STPPaymentHandler(apiClient: STPAPIClient(publishableKey: STPTestingDefaultPublishableKey))
        let analyticsClient = STPAnalyticsClient()
        paymentHandler.analyticsClient = analyticsClient
        paymentHandler.confirmPayment(paymentIntentParams, with: self) { (_, _, _) in
            // ...should send these analytics
            let firstAnalytic = analyticsClient._testLogHistory.first
            XCTAssertEqual(firstAnalytic?["event"] as? String, STPAnalyticEvent.paymentHandlerConfirmStarted.rawValue)
            XCTAssertEqual(firstAnalytic?["intent_id"] as? String, "pi_3P20wFFY0qyl6XeW0dSOQ6W7")
            XCTAssertEqual(firstAnalytic?["payment_method_type"] as? String, "card")
            let lastAnalytic = analyticsClient._testLogHistory.last
            XCTAssertEqual(lastAnalytic?["event"] as? String, STPAnalyticEvent.paymentHandlerConfirmFinished.rawValue)
            XCTAssertEqual(lastAnalytic?["intent_id"] as? String, "pi_3P20wFFY0qyl6XeW0dSOQ6W7")
            XCTAssertEqual(lastAnalytic?["status"] as? String, "failed")
            XCTAssertEqual(lastAnalytic?["payment_method_type"] as? String, "card")
            XCTAssertEqual(lastAnalytic?["error_type"] as? String, "invalid_request_error")
            XCTAssertEqual(lastAnalytic?["error_code"] as? String, "payment_intent_unexpected_state")
            XCTAssertTrue((lastAnalytic?["request_id"] as? String)!.starts(with: "req_"))
            paymentHandlerExpectation.fulfill()
        }
        waitForExpectations(timeout: 10)
    }

    func test_confirm_payment_intent_savedpm_sends_analytic() {
        // Confirming a hardcoded already-confirmed PI with invalid params...
        let paymentIntentParams = STPPaymentIntentParams(clientSecret: "pi_3P20wFFY0qyl6XeW0dSOQ6W7_secret_9V8GkrCOt1MEW8SBmAaGnmT6A")
        paymentIntentParams.paymentMethodId = "pm_123"
        let paymentHandlerExpectation = expectation(description: "paymentHandlerExpectation")
        let paymentHandler = STPPaymentHandler(apiClient: STPAPIClient(publishableKey: STPTestingDefaultPublishableKey))
        let analyticsClient = STPAnalyticsClient()
        paymentHandler.analyticsClient = analyticsClient
        paymentHandler.confirmPayment(paymentIntentParams, with: self) { (_, _, _) in
            // ...should send these analytics
            let firstAnalytic = analyticsClient._testLogHistory.first
            XCTAssertEqual(firstAnalytic?["event"] as? String, STPAnalyticEvent.paymentHandlerConfirmStarted.rawValue)
            XCTAssertEqual(firstAnalytic?["intent_id"] as? String, "pi_3P20wFFY0qyl6XeW0dSOQ6W7")
            XCTAssertEqual(firstAnalytic?["payment_method_id"] as? String, "pm_123")
            let lastAnalytic = analyticsClient._testLogHistory.last
            XCTAssertEqual(lastAnalytic?["event"] as? String, STPAnalyticEvent.paymentHandlerConfirmFinished.rawValue)
            XCTAssertEqual(lastAnalytic?["payment_method_id"] as? String, "pm_123")
            XCTAssertEqual(lastAnalytic?["intent_id"] as? String, "pi_3P20wFFY0qyl6XeW0dSOQ6W7")
            XCTAssertEqual(lastAnalytic?["status"] as? String, "failed")
            XCTAssertEqual(lastAnalytic?["error_type"] as? String, "invalid_request_error")
            XCTAssertEqual(lastAnalytic?["error_code"] as? String, "resource_missing")
            XCTAssertTrue((lastAnalytic?["request_id"] as? String)!.starts(with: "req_"))
            paymentHandlerExpectation.fulfill()
        }
        waitForExpectations(timeout: 10)
    }

    func test_confirm_setup_intent_sends_analytic() {
        let setupIntentParams = STPSetupIntentConfirmParams(clientSecret: "seti_1P1xLBFY0qyl6XeWc7c2LrMK_secret_PrgithiYFFPH0NVGP1BK7Oy9OU3mrDT", paymentMethodType: .card)
        // Confirming a hardcoded already-confirmed SI with invalid params...
        setupIntentParams.paymentMethodParams = STPPaymentMethodParams(type: .card)

        let paymentHandlerExpectation = expectation(description: "paymentHandlerExpectation")
        let paymentHandler = STPPaymentHandler(apiClient: STPAPIClient(publishableKey: STPTestingDefaultPublishableKey))
        let analyticsClient = STPAnalyticsClient()
        paymentHandler.analyticsClient = analyticsClient
        paymentHandler.confirmSetupIntent(setupIntentParams, with: self) { (_, _, _) in
            // ...should send these analytics
            let firstAnalytic = analyticsClient._testLogHistory.first
            XCTAssertEqual(firstAnalytic?["event"] as? String, STPAnalyticEvent.paymentHandlerConfirmStarted.rawValue)
            XCTAssertEqual(firstAnalytic?["intent_id"] as? String, "seti_1P1xLBFY0qyl6XeWc7c2LrMK")
            XCTAssertEqual(firstAnalytic?["payment_method_type"] as? String, "card")
            let lastAnalytic = analyticsClient._testLogHistory.last
            XCTAssertEqual(lastAnalytic?["event"] as? String, STPAnalyticEvent.paymentHandlerConfirmFinished.rawValue)
            XCTAssertEqual(lastAnalytic?["intent_id"] as? String, "seti_1P1xLBFY0qyl6XeWc7c2LrMK")
            XCTAssertEqual(lastAnalytic?["status"] as? String, "failed")
            XCTAssertEqual(lastAnalytic?["payment_method_type"] as? String, "card")
            XCTAssertEqual(lastAnalytic?["error_type"] as? String, "invalid_request_error")
            XCTAssertEqual(lastAnalytic?["error_code"] as? String, "parameter_missing")
            XCTAssertTrue((lastAnalytic?["request_id"] as? String)!.starts(with: "req_"))
            paymentHandlerExpectation.fulfill()
        }
        waitForExpectations(timeout: 10)
    }

    func test_confirm_setup_intent_savedpm_sends_analytic() {
        let setupIntentParams = STPSetupIntentConfirmParams(clientSecret: "seti_1P1xLBFY0qyl6XeWc7c2LrMK_secret_PrgithiYFFPH0NVGP1BK7Oy9OU3mrDT")
        // Confirming a hardcoded already-confirmed SI with invalid params...
        setupIntentParams.paymentMethodID = "pm_123"

        let paymentHandlerExpectation = expectation(description: "paymentHandlerExpectation")
        let paymentHandler = STPPaymentHandler(apiClient: STPAPIClient(publishableKey: STPTestingDefaultPublishableKey))
        let analyticsClient = STPAnalyticsClient()
        paymentHandler.analyticsClient = analyticsClient
        paymentHandler.confirmSetupIntent(setupIntentParams, with: self) { (_, _, _) in
            // ...should send these analytics
            let firstAnalytic = analyticsClient._testLogHistory.first
            XCTAssertEqual(firstAnalytic?["event"] as? String, STPAnalyticEvent.paymentHandlerConfirmStarted.rawValue)
            XCTAssertEqual(firstAnalytic?["intent_id"] as? String, "seti_1P1xLBFY0qyl6XeWc7c2LrMK")
            XCTAssertEqual(firstAnalytic?["payment_method_id"] as? String, "pm_123")
            let lastAnalytic = analyticsClient._testLogHistory.last
            XCTAssertEqual(lastAnalytic?["event"] as? String, STPAnalyticEvent.paymentHandlerConfirmFinished.rawValue)
            XCTAssertEqual(lastAnalytic?["intent_id"] as? String, "seti_1P1xLBFY0qyl6XeWc7c2LrMK")
            XCTAssertEqual(lastAnalytic?["payment_method_id"] as? String, "pm_123")
            XCTAssertEqual(lastAnalytic?["status"] as? String, "failed")
            XCTAssertEqual(lastAnalytic?["error_type"] as? String, "invalid_request_error")
            XCTAssertEqual(lastAnalytic?["error_code"] as? String, "resource_missing")
            XCTAssertTrue((lastAnalytic?["request_id"] as? String)!.starts(with: "req_"))
            paymentHandlerExpectation.fulfill()
        }
        waitForExpectations(timeout: 10)
    }

    func test_handle_next_action_payment_intent_sends_analytic() {
        // Calling handleNextAction(forPayment:) with an invalid PI client secret...
        let paymentHandlerExpectation = expectation(description: "paymentHandlerExpectation")
        let paymentHandler = STPPaymentHandler(apiClient: STPAPIClient(publishableKey: STPTestingDefaultPublishableKey))
        let analyticsClient = STPAnalyticsClient()
        paymentHandler.analyticsClient = analyticsClient
        paymentHandler.handleNextAction(forPayment: "pi_3P232pFY0qyl6XeW0FFRtE0A_secret_foo", with: self, returnURL: nil) { (_, _, _) in
            // ...should send these analytics
            let firstAnalytic = analyticsClient._testLogHistory.first
            XCTAssertEqual(firstAnalytic?["event"] as? String, STPAnalyticEvent.paymentHandlerHandleNextActionStarted.rawValue)
            XCTAssertEqual(firstAnalytic?["intent_id"] as? String, "pi_3P232pFY0qyl6XeW0FFRtE0A")
            let lastAnalytic = analyticsClient._testLogHistory.last
            XCTAssertEqual(lastAnalytic?["event"] as? String, STPAnalyticEvent.paymentHandlerHandleNextActionFinished.rawValue)
            XCTAssertEqual(lastAnalytic?["intent_id"] as? String, "pi_3P232pFY0qyl6XeW0FFRtE0A")
            XCTAssertEqual(lastAnalytic?["status"] as? String, "failed")
            XCTAssertEqual(lastAnalytic?["error_type"] as? String, "invalid_request_error")
            XCTAssertEqual(lastAnalytic?["error_code"] as? String, "payment_intent_invalid_parameter")
            XCTAssertTrue((lastAnalytic?["request_id"] as? String)!.starts(with: "req_"))
            paymentHandlerExpectation.fulfill()
        }
        waitForExpectations(timeout: 10)
    }

    func test_handle_next_action_2_payment_intent_sends_analytic() {
        // Calling handleNextAction(for:) with a STPPaymentIntent w/ an unknown next action...
        let paymentHandlerExpectation = expectation(description: "paymentHandlerExpectation")
        let paymentIntent = STPFixtures.paymentIntent(paymentMethodTypes: ["card"], status: .requiresAction, paymentMethod: STPTestUtils.jsonNamed(STPTestJSONPaymentMethodCard), nextAction: .unknown)

        let paymentHandler = STPPaymentHandler(apiClient: STPAPIClient(publishableKey: STPTestingDefaultPublishableKey))
        let analyticsClient = STPAnalyticsClient()
        paymentHandler.analyticsClient = analyticsClient
        paymentHandler.handleNextAction(for: paymentIntent, with: self, returnURL: nil) { (_, _, _) in
            // ...should send these analytics
            let firstAnalytic = analyticsClient._testLogHistory.first
            XCTAssertEqual(firstAnalytic?["event"] as? String, STPAnalyticEvent.paymentHandlerHandleNextActionStarted.rawValue)
            XCTAssertEqual(firstAnalytic?["intent_id"] as? String, "123")
            let lastAnalytic = analyticsClient._testLogHistory.last
            XCTAssertEqual(lastAnalytic?["event"] as? String, STPAnalyticEvent.paymentHandlerHandleNextActionFinished.rawValue)
            XCTAssertEqual(lastAnalytic?["payment_method_id"] as? String, "pm_123456789")
            XCTAssertEqual(lastAnalytic?["intent_id"] as? String, "123")
            XCTAssertEqual(lastAnalytic?["status"] as? String, "failed")
            XCTAssertEqual(lastAnalytic?["error_type"] as? String, "STPPaymentHandlerErrorDomain")
            XCTAssertEqual(lastAnalytic?["error_code"] as? String, "unsupportedAuthenticationErrorCode")
            XCTAssertEqual(lastAnalytic?["error_details"] as? [String: String], [
                "NSLocalizedDescription": "There was an unexpected error -- try again in a few seconds",
                "com.stripe.lib:ErrorMessageKey": "Unknown authentication action type",
            ])
            paymentHandlerExpectation.fulfill()
        }
        waitForExpectations(timeout: 10)
    }

    func test_handle_next_action_setup_intent_sends_analytic() {
        // Calling handleNextAction(forSetupIntent:) with an invalid SI client secret...
        let paymentHandlerExpectation = expectation(description: "paymentHandlerExpectation")
        let paymentHandler = STPPaymentHandler(apiClient: STPAPIClient(publishableKey: STPTestingDefaultPublishableKey))
        let analyticsClient = STPAnalyticsClient()
        paymentHandler.analyticsClient = analyticsClient
        paymentHandler.handleNextAction(forSetupIntent: "seti_3P232pFY0qyl6XeW0FFRtE0A_secret_foo", with: self, returnURL: nil) { (_, _, _) in
            // ...should send these analytics
            let firstAnalytic = analyticsClient._testLogHistory.first
            XCTAssertEqual(firstAnalytic?["event"] as? String, STPAnalyticEvent.paymentHandlerHandleNextActionStarted.rawValue)
            XCTAssertEqual(firstAnalytic?["intent_id"] as? String, "seti_3P232pFY0qyl6XeW0FFRtE0A")
            let lastAnalytic = analyticsClient._testLogHistory.last
            XCTAssertEqual(lastAnalytic?["event"] as? String, STPAnalyticEvent.paymentHandlerHandleNextActionFinished.rawValue)
            XCTAssertEqual(lastAnalytic?["intent_id"] as? String, "seti_3P232pFY0qyl6XeW0FFRtE0A")
            XCTAssertEqual(lastAnalytic?["status"] as? String, "failed")
            XCTAssertEqual(lastAnalytic?["error_type"] as? String, "invalid_request_error")
            XCTAssertEqual(lastAnalytic?["error_code"] as? String, "resource_missing")
            XCTAssertTrue((lastAnalytic?["request_id"] as? String)!.starts(with: "req_"))
            paymentHandlerExpectation.fulfill()
        }
        waitForExpectations(timeout: 10)
    }

    func test_handle_next_action_2_setup_intent_sends_analytic() {
        // Calling handleNextAction(for:) with a STPSetupIntent w/ an unknown next action...
        let paymentHandlerExpectation = expectation(description: "paymentHandlerExpectation")
        var siJSON = STPTestUtils.jsonNamed("SetupIntent")!
        siJSON[jsonDict: "next_action"]!["type"] = "foo"
        siJSON["payment_method"] = STPTestUtils.jsonNamed("CardPaymentMethod")!
        let setupIntent = STPSetupIntent.decodedObject(fromAPIResponse: siJSON)!

        let paymentHandler = STPPaymentHandler(apiClient: STPAPIClient(publishableKey: STPTestingDefaultPublishableKey))
        let analyticsClient = STPAnalyticsClient()
        paymentHandler.analyticsClient = analyticsClient
        paymentHandler.handleNextAction(for: setupIntent, with: self, returnURL: nil) { (_, _, _) in
            // ...should send these analytics
            let firstAnalytic = analyticsClient._testLogHistory.first
            XCTAssertEqual(firstAnalytic?["event"] as? String, STPAnalyticEvent.paymentHandlerHandleNextActionStarted.rawValue)
            XCTAssertEqual(firstAnalytic?["intent_id"] as? String, "seti_123456789")
            XCTAssertEqual(firstAnalytic?["payment_method_id"] as? String, "pm_123456789")
            let lastAnalytic = analyticsClient._testLogHistory.last
            XCTAssertEqual(lastAnalytic?["event"] as? String, STPAnalyticEvent.paymentHandlerHandleNextActionFinished.rawValue)
            XCTAssertEqual(lastAnalytic?["payment_method_id"] as? String, "pm_123456789")
            XCTAssertEqual(lastAnalytic?["intent_id"] as? String, "seti_123456789")
            XCTAssertEqual(lastAnalytic?["status"] as? String, "failed")
            XCTAssertEqual(lastAnalytic?["error_type"] as? String, "STPPaymentHandlerErrorDomain")
            XCTAssertEqual(lastAnalytic?["error_code"] as? String, "unsupportedAuthenticationErrorCode")
            XCTAssertEqual(lastAnalytic?["error_details"] as? [String: String], [
                "NSLocalizedDescription": "There was an unexpected error -- try again in a few seconds",
                "com.stripe.lib:ErrorMessageKey": "Unknown authentication action type",
            ])
            paymentHandlerExpectation.fulfill()
        }
        waitForExpectations(timeout: 10)
    }
}
