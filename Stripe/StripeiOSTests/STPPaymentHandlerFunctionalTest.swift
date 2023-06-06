//
//  STPPaymentHandlerFunctionalTest.swift
//  StripeiOSTests
//
//  Created by Yuki Tokuhiro on 4/24/23.
//

@testable import Stripe
@_spi(STP) @testable import StripePayments
import XCTest

// You can add tests in here for payment methods that don't require customer actions (i.e. don't open webviews for customer authentication).
// If they require customer action, use STPPaymentHandlerFunctionalTest.m instead
final class STPPaymentHandlerFunctionalSwiftTest: XCTestCase, STPAuthenticationContext {
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
            STPTestingAPIClient().createPaymentIntent(withParams: [
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
            STPTestingAPIClient().createPaymentIntent(withParams: [
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
            STPTestingAPIClient().createSetupIntent(withParams: [
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
            STPTestingAPIClient().createSetupIntent(withParams: [
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
}
