//  Converted to Swift 5.8.1 by Swiftify v5.8.28463 - https://swiftify.com/
//
//  STPErrorBridgeTest.swift
//  StripeiOS Tests
//
//  Created by David Estes on 9/23/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import PassKit
import Stripe
import XCTest

class STPErrorBridgeTest: XCTestCase {
    func testSTPErrorBridge() {
        // Grab a constant from each class, just to make sure we didn't forget to include the bridge:
        XCTAssertEqual(Int(STPInvalidRequestError), 50)
        XCTAssertEqual(STPError.errorMessageKey, "com.stripe.lib:ErrorMessageKey")
        let json = [
            "error": [
            "type": "invalid_request_error",
            "message": "Your card number is incorrect.",
            "code": "incorrect_number"
        ]
        ]

        // Make sure we can parse a Stripe response
        let expectedError = Error.stp_error(fromStripeResponse: json)
        XCTAssertEqual((expectedError as NSError?)?.domain, STPError.stripeDomain)
    }
}