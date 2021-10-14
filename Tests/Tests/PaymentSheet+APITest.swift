//
//  PaymentSheet+APITest.swift
//  StripeiOS Tests
//
//  Created by Jaime Park on 6/29/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import XCTest
@testable @_spi(STP) import Stripe

class PaymentSheetAPITest: XCTestCase {
    lazy var configuration: PaymentSheet.Configuration = {
        var config = PaymentSheet.Configuration()
        config.apiClient = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)
        return config
    }()
    func fetchPaymentIntent(types: [String], completion: @escaping (Result<(String), Error>) -> Void) {
        STPTestingAPIClient
            .shared()
            .createPaymentIntent(
                withParams: [
                    "amount": 1050,
                    "currency": "eur",
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

    func fetchSetupIntent(types: [String], completion: @escaping (Result<(String), Error>) -> Void) {
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

    func testPaymentSheetLoadWithPaymentIntent() {
        let expectation = XCTestExpectation(description: "Retrieve Payment Intent With Preferences")
        let types = ["ideal", "card", "bancontact", "sofort"]
        let expected = [.card, .iDEAL, .bancontact, .sofort]
            .filter { PaymentSheet.supportedPaymentMethods.contains($0) }
        
        fetchPaymentIntent(types: types) { result in
            switch result {
            case .success(let clientSecret):
                PaymentSheet.load(
                    clientSecret: IntentClientSecret.paymentIntent(clientSecret: clientSecret),
                    configuration: self.configuration
                ) { result in
                    switch result {
                    case .success((let paymentIntent, let paymentMethods)):
                        expectation.fulfill()
                        XCTAssertEqual(paymentIntent.recommendedPaymentMethodTypes, expected)
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
        let types = ["ideal", "card", "bancontact", "sofort"]
        let expected: [STPPaymentMethodType] = [.card]
        fetchSetupIntent(types: types) { result in
            switch result {
            case .success(let clientSecret):
                PaymentSheet.load(
                    clientSecret: IntentClientSecret.setupIntent(clientSecret: clientSecret),
                    configuration: self.configuration
                ) { result in
                    switch result {
                    case .success((let setupIntent, let paymentMethods)):
                        expectation.fulfill()
                        XCTAssertEqual(setupIntent.recommendedPaymentMethodTypes, expected)
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
    
    func testPaymentSheetFailsLoadWhenNoSupportedPaymentMethods() {
        // When PaymentSheet doesn't support any of the payment methods on the PaymentIntent or SetupIntent...
        let originalSupportedPaymentMethods = PaymentSheet.supportedPaymentMethods
        PaymentSheet.supportedPaymentMethods = []
        defer {
            PaymentSheet.supportedPaymentMethods = originalSupportedPaymentMethods
        }
        let paymentSheetExpectation = expectation(description: "paymentSheetExpectation")
        paymentSheetExpectation.expectedFulfillmentCount = 2
        let flowControllerExpectation = expectation(description: "flowControllerExpectation")
        flowControllerExpectation.expectedFulfillmentCount = 2
        let testWithIntent: (IntentClientSecret) -> () = { intentClientSecret in
            // ...PaymentSheet returns an error
            let paymentSheet = PaymentSheet(intentClientSecret: intentClientSecret, configuration: self.configuration)
            paymentSheet.present(from: UIViewController()) { result in
                guard case .failed(let error) = result else {
                    XCTFail("PaymentSheetResult should be .failed")
                    return
                }
                guard let error = error as? PaymentSheetError, case .noSupportedPaymentMethods = error else {
                    XCTFail("Error should be PaymentSheetError.noSupportedPaymentMethods")
                    return
                }
                paymentSheetExpectation.fulfill()
            }
            PaymentSheet.FlowController.create(clientSecret: intentClientSecret, configuration: self.configuration) { result in
                guard case .failure(let error) = result else {
                    XCTFail("FlowController create result should be .failed")
                    return
                }
                guard let error = error as? PaymentSheetError, case .noSupportedPaymentMethods = error else {
                    XCTFail("Error should be PaymentSheetError.noSupportedPaymentMethods")
                    XCTFail()
                    return
                }
                flowControllerExpectation.fulfill()
            }
        }

        fetchPaymentIntent(types: ["card"]) { result in
            guard case .success(let clientSecret) = result else {
                XCTFail()
                return
            }
            testWithIntent(.paymentIntent(clientSecret: clientSecret))
        }
        fetchSetupIntent(types: ["card"]) { result in
            guard case .success(let clientSecret) = result else {
                XCTFail()
                return
            }
            testWithIntent(.setupIntent(clientSecret: clientSecret))
        }
        waitForExpectations(timeout: STPTestingNetworkRequestTimeout, handler: nil)
    }
}
