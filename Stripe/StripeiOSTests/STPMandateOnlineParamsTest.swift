//
//  STPMandateOnlineParamsTest.swift
//  StripeiOS Tests
//
//  Created by Cameron Sabol on 10/18/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//
@testable@_spi(STP) import Stripe
@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePayments
@testable@_spi(STP) import StripePaymentsUI

class STPMandateOnlineParamsTest: XCTestCase {
    func testRootObjectName() {
        XCTAssertEqual(STPMandateOnlineParams.rootObjectName(), "online")
    }

    func testEncoding() {
        var params = STPMandateOnlineParams(ipAddress: "test_ip_address", userAgent: "a_user_agent")
        var paramsAsDict = STPFormEncoder.dictionary(forObject: params)
        var expected: [String: AnyHashable] = [
            "online": [
                "ip_address": "test_ip_address",
                "user_agent": "a_user_agent",
            ],
        ]
        XCTAssertEqual(paramsAsDict as NSDictionary, expected as NSDictionary)

        params = STPMandateOnlineParams(ipAddress: "", userAgent: "")
        params.inferFromClient = NSNumber(value: true)
        paramsAsDict = STPFormEncoder.dictionary(forObject: params)
        expected = [
            "online": [
                "infer_from_client": NSNumber(value: true)
            ],
        ]
        XCTAssertEqual(paramsAsDict as NSDictionary, expected as NSDictionary)
    }

    // MARK: - Decoding Tests

    func testDecodingValidOnlineParams() {
        let json = [
            "ip_address": "127.0.0.1",
            "user_agent": "Mozilla/5.0",
        ] as [String: Any]

        let onlineParams = STPMandateOnlineParams.decodedObject(fromAPIResponse: json)

        XCTAssertNotNil(onlineParams)
        XCTAssertEqual(onlineParams?.ipAddress, "127.0.0.1")
        XCTAssertEqual(onlineParams?.userAgent, "Mozilla/5.0")
    }

    func testDecodingMissingIPAddress() {
        let json = [
            "user_agent": "Mozilla/5.0"
        ] as [String: Any]

        let onlineParams = STPMandateOnlineParams.decodedObject(fromAPIResponse: json)

        // Should still create the object with empty string for missing IP address
        XCTAssertNotNil(onlineParams)
        XCTAssertEqual(onlineParams?.ipAddress, "")
        XCTAssertEqual(onlineParams?.userAgent, "Mozilla/5.0")
    }

    func testDecodingMissingUserAgent() {
        let json = [
            "ip_address": "127.0.0.1"
        ] as [String: Any]

        let onlineParams = STPMandateOnlineParams.decodedObject(fromAPIResponse: json)

        // Should still create the object with empty string for missing user agent
        XCTAssertNotNil(onlineParams)
        XCTAssertEqual(onlineParams?.ipAddress, "127.0.0.1")
        XCTAssertEqual(onlineParams?.userAgent, "")
    }

    func testDecodingNullIPAddress() {
        let json = [
            "ip_address": NSNull(),
            "user_agent": "Mozilla/5.0",
        ] as [String: Any]

        let onlineParams = STPMandateOnlineParams.decodedObject(fromAPIResponse: json)

        // Should create the object with empty string for null IP address
        XCTAssertNotNil(onlineParams)
        XCTAssertEqual(onlineParams?.ipAddress, "")
        XCTAssertEqual(onlineParams?.userAgent, "Mozilla/5.0")
    }

    func testDecodingNullUserAgent() {
        let json = [
            "ip_address": "127.0.0.1",
            "user_agent": NSNull(),
        ] as [String: Any]

        let onlineParams = STPMandateOnlineParams.decodedObject(fromAPIResponse: json)

        // Should create the object with empty string for null user agent
        XCTAssertNotNil(onlineParams)
        XCTAssertEqual(onlineParams?.ipAddress, "127.0.0.1")
        XCTAssertEqual(onlineParams?.userAgent, "")
    }

    func testDecodingEmptyResponse() {
        let json = [:] as [String: Any]

        let onlineParams = STPMandateOnlineParams.decodedObject(fromAPIResponse: json)

        // Should create the object with empty strings for all missing fields
        XCTAssertNotNil(onlineParams)
        XCTAssertEqual(onlineParams?.ipAddress, "")
        XCTAssertEqual(onlineParams?.userAgent, "")
    }

    func testDecodingNilResponse() {
        let onlineParams = STPMandateOnlineParams.decodedObject(fromAPIResponse: nil)
        XCTAssertNil(onlineParams, "decodedObject should return nil for nil response")
    }

    func testDecodingInvalidDataTypes() {
        let json = [
            "ip_address": 12345,  // Wrong type
            "user_agent": true,     // Wrong type
        ] as [String: Any]

        let onlineParams = STPMandateOnlineParams.decodedObject(fromAPIResponse: json)

        // Should create the object with empty strings for invalid data types
        XCTAssertNotNil(onlineParams)
        XCTAssertEqual(onlineParams?.ipAddress, "")
        XCTAssertEqual(onlineParams?.userAgent, "")
    }

    func testAllResponseFieldsPreserved() {
        let json = [
            "ip_address": "127.0.0.1",
            "user_agent": "Mozilla/5.0",
            "custom_field": "custom_value",
        ] as [String: Any]

        let onlineParams = STPMandateOnlineParams.decodedObject(fromAPIResponse: json)

        XCTAssertNotNil(onlineParams)
        XCTAssertNotNil(onlineParams?.allResponseFields)
        XCTAssertEqual(onlineParams?.allResponseFields["ip_address"] as? String, "127.0.0.1")
        XCTAssertEqual(onlineParams?.allResponseFields["user_agent"] as? String, "Mozilla/5.0")
        XCTAssertEqual(onlineParams?.allResponseFields["custom_field"] as? String, "custom_value")
    }
}
