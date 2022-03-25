//
//  STPPaymentMethodUSBankAccountTest.swift
//  StripeiOS Tests
//
//  Created by Cameron Sabol on 3/2/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import XCTest
import StripeCoreTestUtils
@testable import Stripe


class STPPaymentMethodUSBankAccountTest: XCTestCase {

    static let usBankAccountPaymentIntentClientSecret = "pi_3KhHLqFY0qyl6XeW1X2ZMsOT_secret_k5bOLoKJEW8ZhQFpokL0OrpbU"

    func retrieveUSBankAccountJSON(_ completion: @escaping ([AnyHashable: Any]?) -> Void) {
        let client = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)
        client.retrievePaymentIntent(
            withClientSecret: Self.usBankAccountPaymentIntentClientSecret,
            expand: ["payment_method"]
        ) { paymentIntent, _ in
            let klarnaJson = paymentIntent?.paymentMethod?.usBankAccount?.allResponseFields
            completion(klarnaJson ?? [:])
        }
    }

    func testObjectDecoding() {
        let retrieveJSON = XCTestExpectation(description: "Retrieve JSON")

        retrieveUSBankAccountJSON({ json in
            let usBankAccount = STPPaymentMethodUSBankAccount.decodedObject(fromAPIResponse: json)
            XCTAssertNotNil(usBankAccount, "Failed to decode JSON")
            XCTAssertEqual(usBankAccount?.last4, "6789")
            XCTAssertEqual(usBankAccount?.routingNumber, "110000000")
            XCTAssertEqual(usBankAccount?.bankName, "STRIPE TEST BANK")
            XCTAssertEqual(usBankAccount?.accountHolderType, .individual)
            XCTAssertEqual(usBankAccount?.accountType, .checking)
            XCTAssertNotNil(usBankAccount?.fingerprint)
            retrieveJSON.fulfill()
        })

        wait(for: [retrieveJSON], timeout: STPTestingNetworkRequestTimeout)
    }

}
