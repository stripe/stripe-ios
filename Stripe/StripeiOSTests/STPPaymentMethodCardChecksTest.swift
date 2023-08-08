//  Converted to Swift 5.8.1 by Swiftify v5.8.28463 - https://swiftify.com/
//
//  STPPaymentMethodCardChecksTest.m
//  StripeiOS Tests
//
//  Created by Yuki Tokuhiro on 3/5/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

@testable import StripePayments
import XCTest

class STPPaymentMethodCardChecksTest: XCTestCase {
    func testDecodedObjectFromAPIResponse() {
        let response = [
            "address_line1_check": NSNull(),
            "address_postal_code_check": NSNull(),
            "cvc_check": NSNull(),
        ]
        let requiredFields: [String]? = []

        for field in requiredFields ?? [] {
            var mutableResponse = response
            mutableResponse.removeValue(forKey: field)
            XCTAssertNil(STPPaymentMethodCardChecks.decodedObject(fromAPIResponse: mutableResponse))
        }
        let checks = STPPaymentMethodCardChecks.decodedObject(fromAPIResponse: response)
        XCTAssertNotNil(checks)
        // #pragma clang diagnostic push
        // #pragma clang diagnostic ignored "-Wdeprecated"
        XCTAssertEqual(checks?.addressLine1Check, .unknown)
        XCTAssertEqual(checks?.addressPostalCodeCheck, .unknown)
        XCTAssertEqual(checks?.cvcCheck, .unknown)
        // #pragma clang diagnostic pop
    }

    func testCheckResultFromString() {
        XCTAssertEqual(STPPaymentMethodCardChecks.checkResult(from: "pass"), .pass)
        XCTAssertEqual(STPPaymentMethodCardChecks.checkResult(from: "failed"), .failed)
        XCTAssertEqual(STPPaymentMethodCardChecks.checkResult(from: "unavailable"), .unavailable)
        XCTAssertEqual(STPPaymentMethodCardChecks.checkResult(from: "unchecked"), .unchecked)
        XCTAssertEqual(STPPaymentMethodCardChecks.checkResult(from: "unknown_string"), .unknown)
        XCTAssertEqual(STPPaymentMethodCardChecks.checkResult(from: nil), .unknown)
    }
}
