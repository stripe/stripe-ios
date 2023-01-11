//
//  STPE2ETest.swift
//  StripeiOS Tests
//
//  Created by David Estes on 2/16/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Stripe
import XCTest

class STPE2ETest: XCTestCase {
    let E2ETestTimeout: TimeInterval = 120

    struct E2EExpectation {
        var amount: Int
        var currency: String
        var accountID: String
    }

    class E2EBackend {
        static let backendAPIURL = URL(
            string: "https://stp-mobile-ci-test-backend-e1b3.stripedemos.com/e2e"
        )!

        func createPaymentIntent(
            completion: @escaping (STPPaymentIntentParams, E2EExpectation) -> Void
        ) {
            requestAPI("create_pi", method: "POST") { (json) in
                let paymentIntentClientSecret = json["paymentIntent"] as! String
                let expectedAmount = json["expectedAmount"] as! Int
                let expectedCurrency = json["expectedCurrency"] as! String
                let expectedAccountID = json["expectedAccountID"] as! String
                let publishableKey = json["publishableKey"] as! String
                STPAPIClient.shared.publishableKey = publishableKey
                completion(
                    STPPaymentIntentParams(clientSecret: paymentIntentClientSecret),
                    E2EExpectation(
                        amount: expectedAmount,
                        currency: expectedCurrency,
                        accountID: expectedAccountID
                    )
                )
            }
        }

        func fetchPaymentIntent(id: String, completion: @escaping (E2EExpectation) -> Void) {
            requestAPI("fetch_pi", queryItems: [URLQueryItem(name: "pi", value: id)]) { (json) in
                let resultAmount = json["amount"] as! Int
                let resultCurrency = json["currency"] as! String
                let resultAccountID = json["on_behalf_of"] as! String
                completion(
                    E2EExpectation(
                        amount: resultAmount,
                        currency: resultCurrency,
                        accountID: resultAccountID
                    )
                )
            }
        }

        private func requestAPI(
            _ resource: String,
            method: String = "GET",
            queryItems: [URLQueryItem] = [],
            completion: @escaping ([String: Any]) -> Void
        ) {
            var url = URLComponents(
                url: Self.backendAPIURL.appendingPathComponent(resource),
                resolvingAgainstBaseURL: false
            )!
            url.queryItems = queryItems
            var request = URLRequest(url: url.url!)
            request.httpMethod = method
            let task = URLSession.shared.dataTask(
                with: request,
                completionHandler: { (data, _, error) in
                    guard let data = data,
                        let json = try? JSONSerialization.jsonObject(with: data, options: [])
                            as? [String: Any]
                    else {
                        XCTFail(
                            "Did not receive valid JSON response from E2E server. \(String(describing: error))"
                        )
                        return
                    }
                    DispatchQueue.main.async {
                        completion(json)
                    }
                }
            )
            task.resume()
        }
    }

    static let TestPM: STPPaymentMethodParams = {
        let testCard = STPPaymentMethodCardParams()
        testCard.number = "4242424242424242"
        testCard.expYear = 2050
        testCard.expMonth = 12
        testCard.cvc = "123"
        return STPPaymentMethodParams(card: testCard, billingDetails: nil, metadata: nil)
    }()

    // MARK: LOG.04.01c
    // In this test, a PaymentIntent object is created from an example merchant backend,
    // confirmed by the iOS SDK, and then retrieved to validate that the original amount,
    // currency, and merchant are the same as the original inputs.
    func testE2E() throws {
        continueAfterFailure = false
        let backend = E2EBackend()
        let createPI = XCTestExpectation(description: "Create PaymentIntent")
        let fetchPIBackend = XCTestExpectation(
            description: "Fetch and check PaymentIntent via backend"
        )
        let fetchPIClient = XCTestExpectation(
            description: "Fetch and check PaymentIntent via client"
        )
        let confirmPI = XCTestExpectation(description: "Confirm PaymentIntent")

        // Create a PaymentIntent
        backend.createPaymentIntent { (pip, expected) in
            createPI.fulfill()

            // Confirm the PaymentIntent using a test card
            pip.paymentMethodParams = STPE2ETest.TestPM
            STPAPIClient.shared.confirmPaymentIntent(with: pip) { (confirmedPI, confirmError) in
                confirmPI.fulfill()
                XCTAssertNotNil(confirmedPI)
                XCTAssertNil(confirmError)

                // Check the PI information using the backend
                backend.fetchPaymentIntent(id: pip.stripeId!) { (expectationResult) in
                    XCTAssertEqual(expectationResult.amount, expected.amount)
                    XCTAssertEqual(expectationResult.accountID, expected.accountID)
                    XCTAssertEqual(expectationResult.currency, expected.currency)
                    fetchPIBackend.fulfill()
                }

                // Check the PI information using the client
                STPAPIClient.shared.retrievePaymentIntent(withClientSecret: pip.clientSecret) {
                    (fetchedPI, fetchError) in
                    XCTAssertNil(fetchError)
                    let fetchedPI = fetchedPI!
                    XCTAssertEqual(fetchedPI.status, .succeeded)
                    XCTAssertEqual(fetchedPI.amount, expected.amount)
                    XCTAssertEqual(fetchedPI.currency, expected.currency)
                    // The client can't check the "on_behalf_of" field, so we check it via the merchant test above.
                    fetchPIClient.fulfill()
                }
            }
        }
        wait(for: [createPI, confirmPI, fetchPIBackend, fetchPIClient], timeout: E2ETestTimeout)
    }
}
