//
//  STPPaymentMethodAffirmTests.swift
//  StripeiOS Tests
//
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import XCTest
import StripeCoreTestUtils
@testable import Stripe

class STPPaymentMethodAffirmTests: XCTestCase {

    static let affirmPaymentIntentClientSecret = "pi_3KUFbTFY0qyl6XeW1oDBbiQk_secret_8kdpLx37oa5WMrI2xoXThCK9s"

    func _retrieveAffirmJSON(_ completion: @escaping ([AnyHashable: Any]?) -> Void) {
        let client = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)
        client.retrievePaymentIntent(
            withClientSecret: Self.affirmPaymentIntentClientSecret,
            expand: ["payment_method"]
        ) { paymentIntent, _ in
            let affirmJson = paymentIntent?.paymentMethod?.affirm?.allResponseFields
            XCTAssertNotNil(paymentIntent?.paymentMethod?.affirm)
            completion(affirmJson ?? [:])
        }
    }

    func testObjectDecoding() {
        let retrieveJSON = XCTestExpectation(description: "Retrieve JSON")

        _retrieveAffirmJSON({ json in
            let affirm = STPPaymentMethodAffirm.decodedObject(fromAPIResponse: json)
            XCTAssertNotNil(affirm, "Failed to decode JSON")
            retrieveJSON.fulfill()
        })

        wait(for: [retrieveJSON], timeout: STPTestingNetworkRequestTimeout)
    }

}
