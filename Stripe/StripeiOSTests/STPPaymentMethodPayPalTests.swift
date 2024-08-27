//  Converted to Swift 5.8.1 by Swiftify v5.8.28463 - https://swiftify.com/
//
//  STPPaymentMethodPayPalTests.m
//  StripeiOS Tests
//
//  Created by Cameron Sabol on 10/7/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import StripeCoreTestUtils
import StripePaymentsTestUtils

class STPPaymentMethodPayPalTests: STPNetworkStubbingTestCase {
    var payPalJSON: [AnyHashable: Any]?

    func _retrievePayPalJSON(_ completion: @escaping ([AnyHashable: Any]?) -> Void) {
        if let payPalJSON {
            completion(payPalJSON)
        } else {
            let client = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)
            client.retrievePaymentIntent(withClientSecret: "pi_1HcI17FY0qyl6XeWcFAAbZCw_secret_oAZ9OCoeyIg8EPeBEdF96ZJOT", expand: ["payment_method"]) { paymentIntent, _ in
                self.payPalJSON = paymentIntent?.lastPaymentError?.paymentMethod?.payPal?.allResponseFields
                completion(self.payPalJSON)
            }
        }
    }

    func testCorrectParsing() {
        let expectation = self.expectation(description: "Retrieve payment intent")
        _retrievePayPalJSON({ json in
            let payPal = STPPaymentMethodPayPal.decodedObject(fromAPIResponse: json)
            XCTAssertNotNil(payPal, "Failed to decode JSON")
            expectation.fulfill()
        })
        waitForExpectations(timeout: STPTestingNetworkRequestTimeout, handler: nil)
    }
}
