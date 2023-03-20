//
//  STPPaymentMethodOptionsTest.swift
//  StripeiOS Tests
//
//  Created by Cameron Sabol on 4/8/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import XCTest
@testable import Stripe

class STPPaymentMethodOptionsTest: XCTestCase {

    func testUSBankAccountOptions_PaymentIntent() {
        let client = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)

        let verificationMethods = [
            "skip",
            "automatic",
            "instant",
            "microdeposits",
            "instant_or_skip",
        ]
        for verificationMethod in verificationMethods {
            var clientSecret: String? = nil
            let createPIExpectation = expectation(description: "Create PaymentIntent")
            STPTestingAPIClient.shared().createPaymentIntent(withParams: ["payment_method_types": ["us_bank_account"],
                                                                          "payment_method_options": ["us_bank_account": ["verification_method": verificationMethod]],
                                                                          "currency": "usd",
                                                                          "amount": 1000],
                                                             account: nil) { intentClientSecret, error in
                XCTAssertNil(error)
                XCTAssertNotNil(intentClientSecret)
                clientSecret = intentClientSecret
                createPIExpectation.fulfill()
            }
            waitForExpectations(timeout: STPTestingNetworkRequestTimeout)
            guard let clientSecret = clientSecret else {
                XCTFail("Failed to create PaymentIntent")
                continue
            }

            let retrievePIExpectation = expectation(description: "Retrieve PaymentIntent")
            client.retrievePaymentIntent(withClientSecret: clientSecret) { paymentIntent, error in
                XCTAssertNil(error)
                XCTAssertNotNil(paymentIntent)

                XCTAssertNotNil(paymentIntent?.paymentMethodOptions?.usBankAccount?.verificationMethod)
                XCTAssertEqual(paymentIntent?.paymentMethodOptions?.usBankAccount?.verificationMethod,
                               STPPaymentMethodOptions.USBankAccount.VerificationMethod(rawValue: verificationMethod))
                retrievePIExpectation.fulfill()

            }
            waitForExpectations(timeout: STPTestingNetworkRequestTimeout)
        }


    }

    func testUSBankAccountOptions_SetupIntent() {
        let client = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)

        let verificationMethods = [
            "skip",
            "automatic",
            "instant",
            "microdeposits",
            "instant_or_skip",
        ]
        for verificationMethod in verificationMethods {
            var clientSecret: String? = nil
            let createPIExpectation = expectation(description: "Create SetupIntent")
            STPTestingAPIClient.shared().createSetupIntent(withParams: ["payment_method_types": ["us_bank_account"],
                                                                        "payment_method_options": ["us_bank_account": ["verification_method": verificationMethod]],
                                                                       ],
                                                           account: nil) { intentClientSecret, error in
                XCTAssertNil(error)
                XCTAssertNotNil(intentClientSecret)
                clientSecret = intentClientSecret
                createPIExpectation.fulfill()
            }
            waitForExpectations(timeout: STPTestingNetworkRequestTimeout)
            guard let clientSecret = clientSecret else {
                XCTFail("Failed to create SetupIntent")
                continue
            }

            let retrievePIExpectation = expectation(description: "Retrieve PaymentIntent")
            client.retrieveSetupIntent(withClientSecret: clientSecret) { setupIntent, error in
                XCTAssertNil(error)
                XCTAssertNotNil(setupIntent)

                XCTAssertNotNil(setupIntent?.paymentMethodOptions?.usBankAccount?.verificationMethod)
                XCTAssertEqual(setupIntent?.paymentMethodOptions?.usBankAccount?.verificationMethod,
                               STPPaymentMethodOptions.USBankAccount.VerificationMethod(rawValue: verificationMethod))
                retrievePIExpectation.fulfill()

            }
            waitForExpectations(timeout: STPTestingNetworkRequestTimeout)
        }


    }

}
