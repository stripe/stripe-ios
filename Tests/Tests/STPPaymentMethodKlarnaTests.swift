//
//  STPPaymentMethodKlarnaTests.swift
//  StripeiOS Tests
//
//  Created by Nick Porter on 10/21/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import XCTest
import StripeCoreTestUtils
@testable import Stripe

class STPPaymentMethodKlarnaTests: XCTestCase {

    static let klarnaPaymentIntentClientSecret = "pi_3Jn3kUFY0qyl6XeW0mCp95UD_secret_28aNjjd1zsySFWvGoSzgcR5Qw"

    func _retrieveKlarnaJSON(_ completion: @escaping ([AnyHashable: Any]?) -> Void) {
        let client = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)
        client.retrievePaymentIntent(
            withClientSecret: Self.klarnaPaymentIntentClientSecret,
            expand: ["payment_method"]
        ) { paymentIntent, _ in
            let klarnaJson = paymentIntent?.paymentMethod?.klarna?.allResponseFields
            completion(klarnaJson ?? [:])
        }
    }

    func testObjectDecoding() {
        let retrieveJSON = XCTestExpectation(description: "Retrieve JSON")

        _retrieveKlarnaJSON({ json in
            let klarna = STPPaymentMethodKlarna.decodedObject(fromAPIResponse: json)
            XCTAssertNotNil(klarna, "Failed to decode JSON")
            retrieveJSON.fulfill()
        })

        wait(for: [retrieveJSON], timeout: STPTestingNetworkRequestTimeout)
    }

}
