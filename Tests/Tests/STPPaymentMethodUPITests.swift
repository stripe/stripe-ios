//
//  STPPaymentMethodUPITests.swift
//  StripeiOS Tests
//
//  Created by Anirudh Bhargava on 11/10/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import StripeCoreTestUtils
@testable import Stripe

class STPPaymentMethodUPITests: XCTestCase {
    private(set) var upiJSON: [AnyHashable: Any]?

    func _retrieveUPIJSON(_ completion: @escaping ([AnyHashable: Any]?) -> Void) {
        if let upiJSON = upiJSON {
            completion(upiJSON)
        } else {
            let client = STPAPIClient(publishableKey: STPTestingINPublishableKey)
            client.retrievePaymentIntent(
                withClientSecret: "pi_1HlYxxBte6TMTRd48W66zjTJ_secret_TgB7p7e7aTRbr22UT6N6KNrSm",
                expand: ["payment_method"]
            ) { [self] paymentIntent, _ in
                upiJSON = paymentIntent?.paymentMethod?.upi?.allResponseFields
                completion(upiJSON ?? [:])
            }
        }
    }

    func testCorrectParsing() {
        let jsonExpectation = XCTestExpectation(description: "Fetch UPI JSON")
        _retrieveUPIJSON({ json in
            let upi = STPPaymentMethodUPI.decodedObject(fromAPIResponse: json)
            XCTAssertNotNil(upi, "Failed to decode JSON")
            jsonExpectation.fulfill()
        })
        wait(for: [jsonExpectation], timeout: STPTestingNetworkRequestTimeout)
    }
}
