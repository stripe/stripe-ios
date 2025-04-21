//  Converted to Swift 5.8.1 by Swiftify v5.8.28463 - https://swiftify.com/
//
//  STPSourceRedirectTest.m
//  Stripe
//
//  Created by Joey Dong on 6/21/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

@testable import StripePayments
import XCTest

class STPSourceRedirectTest: XCTestCase {
    // MARK: - STPSourceRedirectStatus Tests

    func testStatusFromString() {
        XCTAssertEqual(STPSourceRedirect.status(from: "pending"), STPSourceRedirectStatus.pending)
        XCTAssertEqual(STPSourceRedirect.status(from: "PENDING"), STPSourceRedirectStatus.pending)

        XCTAssertEqual(STPSourceRedirect.status(from: "succeeded"), STPSourceRedirectStatus.succeeded)
        XCTAssertEqual(STPSourceRedirect.status(from: "SUCCEEDED"), STPSourceRedirectStatus.succeeded)

        XCTAssertEqual(STPSourceRedirect.status(from: "failed"), STPSourceRedirectStatus.failed)
        XCTAssertEqual(STPSourceRedirect.status(from: "FAILED"), STPSourceRedirectStatus.failed)

        XCTAssertEqual(STPSourceRedirect.status(from: "unknown"), STPSourceRedirectStatus.unknown)
        XCTAssertEqual(STPSourceRedirect.status(from: "UNKNOWN"), STPSourceRedirectStatus.unknown)

        XCTAssertEqual(STPSourceRedirect.status(from: "not_required"), STPSourceRedirectStatus.notRequired)
        XCTAssertEqual(STPSourceRedirect.status(from: "NOT_REQUIRED"), STPSourceRedirectStatus.notRequired)

        XCTAssertEqual(STPSourceRedirect.status(from: "garbage"), STPSourceRedirectStatus.unknown)
        XCTAssertEqual(STPSourceRedirect.status(from: "GARBAGE"), STPSourceRedirectStatus.unknown)
    }

    func testStringFromStatus() {
        let values = [
            STPSourceRedirectStatus.pending,
            STPSourceRedirectStatus.succeeded,
            STPSourceRedirectStatus.failed,
            STPSourceRedirectStatus.unknown,
        ]

        for status in values {
            let string = STPSourceRedirect.string(from: status)

            switch status {
            case STPSourceRedirectStatus.pending:
                XCTAssertEqual(string, "pending")
            case STPSourceRedirectStatus.succeeded:
                XCTAssertEqual(string, "succeeded")
            case STPSourceRedirectStatus.failed:
                XCTAssertEqual(string, "failed")
            case STPSourceRedirectStatus.notRequired:
                XCTAssertEqual(string, "not_required")
            case STPSourceRedirectStatus.unknown:
                XCTAssertNil(string)
            default:
                break
            }
        }
    }

    // MARK: - Description Tests

    func testDescription() {
        let redirect = STPSourceRedirect.decodedObject(fromAPIResponse: STPTestUtils.jsonNamed("3DSSource")["redirect"] as? [AnyHashable: Any])
        XCTAssertNotNil(redirect?.description)
    }

    // MARK: - STPAPIResponseDecodable Tests

    func testDecodedObjectFromAPIResponseRequiredFields() {
        let requiredFields = [
            "return_url",
            "status",
            "url",
        ]

        for field in requiredFields {
            var response = STPTestUtils.jsonNamed("3DSSource")["redirect"] as? [AnyHashable: Any]
            response?.removeValue(forKey: field)

            XCTAssertNil(STPSourceRedirect.decodedObject(fromAPIResponse: response))
        }

        XCTAssertNotNil(STPSourceRedirect.decodedObject(fromAPIResponse: STPTestUtils.jsonNamed("3DSSource")["redirect"] as? [AnyHashable: Any]))
    }

    func testDecodedObjectFromAPIResponseMapping() {
        let response = STPTestUtils.jsonNamed("3DSSource")["redirect"] as? [AnyHashable: Any]
        let redirect = STPSourceRedirect.decodedObject(fromAPIResponse: response)

        XCTAssertEqual(redirect?.returnURL, URL(string: "exampleappschema://stripe_callback"))
        XCTAssertEqual(redirect?.status, STPSourceRedirectStatus.pending)
        XCTAssertEqual(redirect?.url, URL(string: "https://hooks.stripe.com/redirect/authenticate/src_19YlvWAHEMiOZZp1QQlOD79v?client_secret=src_client_secret_kBwCSm6Xz5MQETiJ43hUH8qv"))

        XCTAssertEqual(redirect!.allResponseFields as NSDictionary, response! as NSDictionary)
    }
}
