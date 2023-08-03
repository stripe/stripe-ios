//  Converted to Swift 5.8.1 by Swiftify v5.8.28463 - https://swiftify.com/
//
//  STPSourceRedirectTest.swift
//  Stripe
//
//  Created by Joey Dong on 6/21/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

import XCTest

class STPSourceRedirect {
    private class func status(from string: String?) -> STPSourceRedirectStatus {
    }

    private class func string(from status: STPSourceRedirectStatus) -> String? {
    }
}

class STPSourceRedirectTest: XCTestCase {
    // MARK: - STPSourceRedirectStatus Tests

    func testStatusFromString() {
        XCTAssertEqual(Int(STPSourceRedirect.status(from: "pending")), Int(STPSourceRedirectStatusPending))
        XCTAssertEqual(Int(STPSourceRedirect.status(from: "PENDING")), Int(STPSourceRedirectStatusPending))

        XCTAssertEqual(Int(STPSourceRedirect.status(from: "succeeded")), Int(STPSourceRedirectStatusSucceeded))
        XCTAssertEqual(Int(STPSourceRedirect.status(from: "SUCCEEDED")), Int(STPSourceRedirectStatusSucceeded))

        XCTAssertEqual(Int(STPSourceRedirect.status(from: "failed")), Int(STPSourceRedirectStatusFailed))
        XCTAssertEqual(Int(STPSourceRedirect.status(from: "FAILED")), Int(STPSourceRedirectStatusFailed))

        XCTAssertEqual(Int(STPSourceRedirect.status(from: "unknown")), Int(STPSourceRedirectStatusUnknown))
        XCTAssertEqual(Int(STPSourceRedirect.status(from: "UNKNOWN")), Int(STPSourceRedirectStatusUnknown))

        XCTAssertEqual(Int(STPSourceRedirect.status(from: "not_required")), Int(STPSourceRedirectStatusNotRequired))
        XCTAssertEqual(Int(STPSourceRedirect.status(from: "NOT_REQUIRED")), Int(STPSourceRedirectStatusNotRequired))

        XCTAssertEqual(Int(STPSourceRedirect.status(from: "garbage")), Int(STPSourceRedirectStatusUnknown))
        XCTAssertEqual(Int(STPSourceRedirect.status(from: "GARBAGE")), Int(STPSourceRedirectStatusUnknown))
    }

    func testStringFromStatus() {
        let values = [
            NSNumber(value: STPSourceRedirectStatusPending),
            NSNumber(value: STPSourceRedirectStatusSucceeded),
            NSNumber(value: STPSourceRedirectStatusFailed),
            NSNumber(value: STPSourceRedirectStatusUnknown),
        ]

        for statusNumber in values {
            let status = statusNumber.intValue as? STPSourceRedirectStatus
            var string: String?
            if let status {
                string = STPSourceRedirect.string(from: status)
            }

            switch status {
            case STPSourceRedirectStatusPending:
                XCTAssertEqual(string, "pending")
            case STPSourceRedirectStatusSucceeded:
                XCTAssertEqual(string, "succeeded")
            case STPSourceRedirectStatusFailed:
                XCTAssertEqual(string, "failed")
            case STPSourceRedirectStatusNotRequired:
                XCTAssertEqual(string, "not_required")
            case STPSourceRedirectStatusUnknown:
                XCTAssertNil(string)
                break
            default:
                break
            }
        }
    }

    // MARK: - Description Tests

    func testDescription() {
        let redirect = STPSourceRedirect.decodedObject(fromAPIResponse: STPTestUtils.jsonNamed("3DSSource")?["redirect"])
        XCTAssert(redirect?.description)
    }

    // MARK: - STPAPIResponseDecodable Tests

    func testDecodedObjectFromAPIResponseRequiredFields() {
        let requiredFields = [
            "return_url",
            "status",
            "url",
        ]

        for field in requiredFields {
            var response = STPTestUtils.jsonNamed("3DSSource")?["redirect"] as? [AnyHashable : Any]
            response?.removeValue(forKey: field)

            XCTAssertNil(STPSourceRedirect.decodedObject(fromAPIResponse: response))
        }

        XCTAssert(STPSourceRedirect.decodedObject(fromAPIResponse: STPTestUtils.jsonNamed("3DSSource")?["redirect"]))
    }

    func testDecodedObjectFromAPIResponseMapping() {
        let response = STPTestUtils.jsonNamed("3DSSource")?["redirect"] as? [AnyHashable : Any]
        let redirect = STPSourceRedirect.decodedObject(fromAPIResponse: response)

        XCTAssertEqual(redirect?.returnURL, URL(string: "exampleappschema://stripe_callback"))
        XCTAssertEqual(redirect?.status ?? 0, Int(STPSourceRedirectStatusPending))
        XCTAssertEqual(redirect?.url, URL(string: "https://hooks.stripe.com/redirect/authenticate/src_19YlvWAHEMiOZZp1QQlOD79v?client_secret=src_client_secret_kBwCSm6Xz5MQETiJ43hUH8qv"))

        XCTAssertNotEqual(redirect?.allResponseFields, response)
        XCTAssertEqual(redirect?.allResponseFields, response)
    }
}