//  Converted to Swift 5.8.1 by Swiftify v5.8.28463 - https://swiftify.com/
//
//  STPPaymentMethodOXXOTests.m
//  StripeiOS Tests
//
//  Created by Polo Li on 6/16/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import StripeCore
import StripeCoreTestUtils
import StripePaymentsTestUtils

class STPPaymentMethodOXXOTests: STPNetworkStubbingTestCase {
    private(set) var oxxoJSON: [AnyHashable: Any]?

    func _retrieveOXXOJSON(_ completion: @escaping ([AnyHashable: Any]?) -> Void) {
        if let oxxoJSON {
            completion(oxxoJSON)
        } else {
            let client = STPAPIClient(publishableKey: STPTestingMEXPublishableKey)
            client.retrievePaymentIntent(withClientSecret: "pi_1GvAdyHNG4o8pO5l0dr078gf_secret_h0tJE5mSX9BPEkmpKSh93jBXi", expand: ["payment_method"]) { paymentIntent, _ in
                self.oxxoJSON = paymentIntent?.paymentMethod?.oxxo?.allResponseFields
                completion(self.oxxoJSON)
            }
        }
    }

    func testCorrectParsing() {
        let expectation = self.expectation(description: "Retrieve payment intent")
        _retrieveOXXOJSON({ json in
            let oxxo = STPPaymentMethodOXXO.decodedObject(fromAPIResponse: json)
            XCTAssertNotNil(oxxo, "Failed to decode JSON")
            expectation.fulfill()
        })
        waitForExpectations(timeout: STPTestingNetworkRequestTimeout, handler: nil)
    }
}
