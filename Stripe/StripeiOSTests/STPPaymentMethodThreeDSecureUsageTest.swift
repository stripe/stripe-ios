//  Converted to Swift 5.8.1 by Swiftify v5.8.28463 - https://swiftify.com/
//
//  STPPaymentMethodThreeDSecureUsageTest.m
//  StripeiOS Tests
//
//  Created by Yuki Tokuhiro on 3/5/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

import XCTest

class STPPaymentMethodThreeDSecureUsageTest: XCTestCase {
    func testDecodedObjectFromAPIResponse() {
        let response = [
            "supported": NSNumber(value: true)
        ]
        let requiredFields = ["supported"]

        for field in requiredFields {
            var mutableResponse = response
            mutableResponse.removeValue(forKey: field)

            XCTAssertNil(STPPaymentMethodThreeDSecureUsage.decodedObject(fromAPIResponse: mutableResponse))
        }
        XCTAssertNotNil(STPPaymentMethodThreeDSecureUsage.decodedObject(fromAPIResponse: response))
    }
}
