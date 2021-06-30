//
//  STPPaymentSheetTest.swift
//  StripeiOS Tests
//
//  Created by Jaime Park on 6/29/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import XCTest
@testable import Stripe

class STPPaymentSheetTest: XCTestCase {
    func fetchPaymentIntent( completion: @escaping (Result<(String), Error>) -> Void) {
        STPTestingAPIClient
            .shared()
            .createPaymentIntent(
                withParams: [
                    "amount": 1050,
                    "currency": "eur",
                    "payment_method_types": ["card", "ideal", "sepa_debit", "bancontact", "sofort"]
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

    func fetchSetupIntent( completion: @escaping (Result<(String), Error>) -> Void) {
        STPTestingAPIClient
            .shared()
            .createSetupIntent(
                withParams: [
                    "payment_method_types": ["card", "ideal", "sepa_debit", "bancontact", "sofort"]
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

    func testPaymentSheetLoadWithPaymentIntent() {
        let expectation = XCTestExpectation(description: "Retrieve Payment Intent With Preferences")
        
        fetchPaymentIntent() { result in
            switch result {
            case .success(let clientSecret):
                PaymentSheet.load(
                    apiClient: STPAPIClient(publishableKey: STPTestingDefaultPublishableKey),
                    clientSecret: IntentClientSecret.paymentIntent(clientSecret: clientSecret)
                ) { result in
                    switch result {
                    case .success((let paymentIntent, let paymentMethods)):
                        expectation.fulfill()
                        XCTAssertEqual(paymentIntent.orderedPaymentMethodTypes,
                                       [.card, .iDEAL, .SEPADebit, .bancontact, .sofort])
                        XCTAssertEqual(paymentMethods, [])
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

        fetchSetupIntent() { result in
            switch result {
            case .success(let clientSecret):
                PaymentSheet.load(
                    apiClient: STPAPIClient(publishableKey: STPTestingDefaultPublishableKey),
                    clientSecret: IntentClientSecret.setupIntent(clientSecret: clientSecret)
                ) { result in
                    switch result {
                    case .success((let setupIntent, let paymentMethods)):
                        expectation.fulfill()
                        XCTAssertEqual(setupIntent.orderedPaymentMethodTypes,
                                       [.card, .iDEAL, .SEPADebit, .bancontact, .sofort])
                        XCTAssertEqual(paymentMethods, [])
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
}
