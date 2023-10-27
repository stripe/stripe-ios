//  Converted to Swift 5.8.1 by Swiftify v5.8.28463 - https://swiftify.com/
//
//  STPSourceVerificationTest.m
//  Stripe
//
//  Created by Joey Dong on 6/21/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

@testable import StripePayments
import XCTest

class STPSourceVerificationTest: XCTestCase {
    // MARK: - STPSourceVerificationStatus Tests

    func testStatusFromString() {
        XCTAssertEqual(STPSourceVerification.status(from: "pending"), STPSourceVerificationStatus.pending)
        XCTAssertEqual(STPSourceVerification.status(from: "pending"), STPSourceVerificationStatus.pending)

        XCTAssertEqual(STPSourceVerification.status(from: "succeeded"), STPSourceVerificationStatus.succeeded)
        XCTAssertEqual(STPSourceVerification.status(from: "SUCCEEDED"), STPSourceVerificationStatus.succeeded)

        XCTAssertEqual(STPSourceVerification.status(from: "failed"), STPSourceVerificationStatus.failed)
        XCTAssertEqual(STPSourceVerification.status(from: "FAILED"), STPSourceVerificationStatus.failed)

        XCTAssertEqual(STPSourceVerification.status(from: "unknown"), STPSourceVerificationStatus.unknown)
        XCTAssertEqual(STPSourceVerification.status(from: "UNKNOWN"), STPSourceVerificationStatus.unknown)

        XCTAssertEqual(STPSourceVerification.status(from: "garbage"), STPSourceVerificationStatus.unknown)
        XCTAssertEqual(STPSourceVerification.status(from: "GARBAGE"), STPSourceVerificationStatus.unknown)
    }

    func testStringFromStatus() {
        let values = [
            STPSourceVerificationStatus.pending,
            STPSourceVerificationStatus.succeeded,
            STPSourceVerificationStatus.failed,
            STPSourceVerificationStatus.unknown,
        ]

        for status in values {
            let string = STPSourceVerification.string(from: status)

            switch status {
            case STPSourceVerificationStatus.pending:
                XCTAssertEqual(string, "pending")
            case STPSourceVerificationStatus.succeeded:
                XCTAssertEqual(string, "succeeded")
            case STPSourceVerificationStatus.failed:
                XCTAssertEqual(string, "failed")
            case STPSourceVerificationStatus.unknown:
                XCTAssertNil(string)
            default:
                break
            }
        }
    }

    // MARK: - Description Tests

    func testDescription() {
        let verification = STPSourceVerification.decodedObject(fromAPIResponse: STPTestUtils.jsonNamed("SEPADebitSource")["verification"] as? [AnyHashable: Any])
        XCTAssertNotNil(verification?.description)
    }

    // MARK: - STPAPIResponseDecodable Tests

    func testDecodedObjectFromAPIResponseRequiredFields() {
        let requiredFields = [
            "status",
        ]

        for field in requiredFields {
            var response = STPTestUtils.jsonNamed("SEPADebitSource")["verification"] as? [AnyHashable: Any]
            response?.removeValue(forKey: field)

            XCTAssertNil(STPSourceVerification.decodedObject(fromAPIResponse: response))
        }

        XCTAssertNotNil(STPSourceVerification.decodedObject(fromAPIResponse: STPTestUtils.jsonNamed("SEPADebitSource")["verification"] as? [AnyHashable: Any]))
    }

    func testDecodedObjectFromAPIResponseMapping() {
        let response = STPTestUtils.jsonNamed("SEPADebitSource")["verification"] as? [AnyHashable: Any]
        let verification = STPSourceVerification.decodedObject(fromAPIResponse: response)

        XCTAssertEqual(verification?.attemptsRemaining, NSNumber(value: 5))
        XCTAssertEqual(verification?.status, STPSourceVerificationStatus.pending)

        XCTAssertEqual(verification?.allResponseFields as? NSDictionary, response as? NSDictionary)
    }
}
