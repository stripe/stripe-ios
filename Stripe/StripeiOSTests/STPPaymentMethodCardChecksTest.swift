//  Converted to Swift 5.8.1 by Swiftify v5.8.28463 - https://swiftify.com/
//
//  STPPaymentMethodCardChecksTest.swift
//  StripeiOS Tests
//
//  Created by Yuki Tokuhiro on 3/5/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

import XCTest

class STPPaymentMethodCardChecksTest: XCTestCase {
    func testDecodedObjectFromAPIResponse() {
        let response = [
            "address_line1_check": NSNull(),
            "address_postal_code_check": NSNull(),
            "cvc_check": NSNull()
        ]
        let requiredFields: [String]? = []

        for field in requiredFields ?? [] {
            var mutableResponse = response
            mutableResponse.removeValue(forKey: field)
            XCTAssertNil(STPPaymentMethodCardChecks.decodedObject(fromAPIResponse: mutableResponse))
        }
        let checks = STPPaymentMethodCardChecks.decodedObject(fromAPIResponse: response)
        XCTAssertNotNil(Int(checks ?? 0))
        //#pragma clang diagnostic push
        //#pragma clang diagnostic ignored "-Wdeprecated"
        XCTAssertEqual(checks?.addressLine1Check ?? 0, Int(STPPaymentMethodCardCheckResultUnknown))
        XCTAssertEqual(checks?.addressPostalCodeCheck ?? 0, Int(STPPaymentMethodCardCheckResultUnknown))
        XCTAssertEqual(checks?.cvcCheck ?? 0, Int(STPPaymentMethodCardCheckResultUnknown))
        //#pragma clang diagnostic pop
    }

    func testCheckResultFromString() {
        XCTAssertEqual(STPPaymentMethodCardChecks.checkResult(fromString: "pass"), Int(STPPaymentMethodCardCheckResultPass))
        XCTAssertEqual(STPPaymentMethodCardChecks.checkResult(fromString: "failed"), Int(STPPaymentMethodCardCheckResultFailed))
        XCTAssertEqual(STPPaymentMethodCardChecks.checkResult(fromString: "unavailable"), Int(STPPaymentMethodCardCheckResultUnavailable))
        XCTAssertEqual(STPPaymentMethodCardChecks.checkResult(fromString: "unchecked"), Int(STPPaymentMethodCardCheckResultUnchecked))
        XCTAssertEqual(STPPaymentMethodCardChecks.checkResult(fromString: "unknown_string"), Int(STPPaymentMethodCardCheckResultUnknown))
        XCTAssertEqual(STPPaymentMethodCardChecks.checkResult(fromString: nil), Int(STPPaymentMethodCardCheckResultUnknown))
    }
}