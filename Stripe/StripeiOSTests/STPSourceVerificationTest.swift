//  Converted to Swift 5.8.1 by Swiftify v5.8.28463 - https://swiftify.com/
//
//  STPSourceVerificationTest.swift
//  Stripe
//
//  Created by Joey Dong on 6/21/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

import XCTest

class STPSourceVerification {
    private class func status(from string: String?) -> STPSourceVerificationStatus {
    }

    private class func string(from status: STPSourceVerificationStatus) -> String? {
    }
}

class STPSourceVerificationTest: XCTestCase {
    // MARK: - STPSourceVerificationStatus Tests

    func testStatusFromString() {
        XCTAssertEqual(Int(STPSourceVerification.status(from: "pending")), Int(STPSourceVerificationStatusPending))
        XCTAssertEqual(Int(STPSourceVerification.status(from: "pending")), Int(STPSourceVerificationStatusPending))

        XCTAssertEqual(Int(STPSourceVerification.status(from: "succeeded")), Int(STPSourceVerificationStatusSucceeded))
        XCTAssertEqual(Int(STPSourceVerification.status(from: "SUCCEEDED")), Int(STPSourceVerificationStatusSucceeded))

        XCTAssertEqual(Int(STPSourceVerification.status(from: "failed")), Int(STPSourceVerificationStatusFailed))
        XCTAssertEqual(Int(STPSourceVerification.status(from: "FAILED")), Int(STPSourceVerificationStatusFailed))

        XCTAssertEqual(Int(STPSourceVerification.status(from: "unknown")), Int(STPSourceVerificationStatusUnknown))
        XCTAssertEqual(Int(STPSourceVerification.status(from: "UNKNOWN")), Int(STPSourceVerificationStatusUnknown))

        XCTAssertEqual(Int(STPSourceVerification.status(from: "garbage")), Int(STPSourceVerificationStatusUnknown))
        XCTAssertEqual(Int(STPSourceVerification.status(from: "GARBAGE")), Int(STPSourceVerificationStatusUnknown))
    }

    func testStringFromStatus() {
        let values = [
            NSNumber(value: STPSourceVerificationStatusPending),
            NSNumber(value: STPSourceVerificationStatusSucceeded),
            NSNumber(value: STPSourceVerificationStatusFailed),
            NSNumber(value: STPSourceVerificationStatusUnknown),
        ]

        for statusNumber in values {
            let status = statusNumber.intValue as? STPSourceVerificationStatus
            var string: String?
            if let status {
                string = STPSourceVerification.string(from: status)
            }

            switch status {
            case STPSourceVerificationStatusPending:
                XCTAssertEqual(string, "pending")
            case STPSourceVerificationStatusSucceeded:
                XCTAssertEqual(string, "succeeded")
            case STPSourceVerificationStatusFailed:
                XCTAssertEqual(string, "failed")
            case STPSourceVerificationStatusUnknown:
                XCTAssertNil(string)
                break
            default:
                break
            }
        }
    }

    // MARK: - Description Tests

    func testDescription() {
        let verification = STPSourceVerification.decodedObject(fromAPIResponse: STPTestUtils.jsonNamed("SEPADebitSource")?["verification"])
        XCTAssert(verification?.description)
    }

    // MARK: - STPAPIResponseDecodable Tests

    func testDecodedObjectFromAPIResponseRequiredFields() {
        let requiredFields = [
            "status",
        ]

        for field in requiredFields {
            var response = STPTestUtils.jsonNamed("SEPADebitSource")?["verification"] as? [AnyHashable : Any]
            response?.removeValue(forKey: field)

            XCTAssertNil(STPSourceVerification.decodedObject(fromAPIResponse: response))
        }

        XCTAssert(STPSourceVerification.decodedObject(fromAPIResponse: STPTestUtils.jsonNamed("SEPADebitSource")?["verification"]))
    }

    func testDecodedObjectFromAPIResponseMapping() {
        let response = STPTestUtils.jsonNamed("SEPADebitSource")?["verification"] as? [AnyHashable : Any]
        let verification = STPSourceVerification.decodedObject(fromAPIResponse: response)

        XCTAssertEqual(verification?.attemptsRemaining, NSNumber(value: 5))
        XCTAssertEqual(verification?.status ?? 0, Int(STPSourceVerificationStatusPending))

        XCTAssertNotEqual(verification?.allResponseFields, response)
        XCTAssertEqual(verification?.allResponseFields, response)
    }
}