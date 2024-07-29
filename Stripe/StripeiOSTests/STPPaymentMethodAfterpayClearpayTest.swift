//  Converted to Swift 5.8.1 by Swiftify v5.8.28463 - https://swiftify.com/
//
//  STPPaymentMethodAfterpayClearpayTest.m
//  StripeiOS Tests
//
//  Created by Ali Riaz on 1/14/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Stripe
import StripeCoreTestUtils
import StripePaymentsTestUtils

class STPPaymentMethodAfterpayClearpayTest: STPNetworkStubbingTestCase {
    var afterpayJSON: [AnyHashable: Any]?

    func _retrieveAfterpayJSON(_ completion: @escaping ([AnyHashable: Any]?) -> Void) {
        if let afterpayJSON {
            completion(afterpayJSON)
        } else {
            let client = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)
            client.retrievePaymentIntent(withClientSecret: "pi_1HbSAfFY0qyl6XeWRnlezJ7K_secret_t6Ju9Z0hxOvslawK34uC1Wm2b", expand: ["payment_method"]) { paymentIntent, _ in
                self.afterpayJSON = paymentIntent?.paymentMethod?.afterpayClearpay?.allResponseFields
                completion(self.afterpayJSON)
            }
        }
    }

    func testCorrectParsing() {
        let jsonExpectation = XCTestExpectation(description: "Fetch Afterpay Clearpay JSON")
        _retrieveAfterpayJSON({ json in
            let afterpay = STPPaymentMethodAfterpayClearpay.decodedObject(fromAPIResponse: json)
            XCTAssertNotNil(afterpay, "Failed to decode JSON")
            jsonExpectation.fulfill()
        })
        wait(for: [jsonExpectation], timeout: STPTestingNetworkRequestTimeout)
    }
}
