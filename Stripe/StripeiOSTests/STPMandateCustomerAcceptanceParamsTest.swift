//
//  STPMandateCustomerAcceptanceParamsTest.swift
//  StripeiOS Tests
//
//  Created by Cameron Sabol on 10/18/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//
@testable@_spi(STP) import Stripe
@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePayments
@testable@_spi(STP) import StripePaymentSheet
@testable@_spi(STP) import StripePaymentsUI

class STPMandateCustomerAcceptanceParamsTest: XCTestCase {
    func testRootObjectName() {
        XCTAssertEqual(STPMandateCustomerAcceptanceParams.rootObjectName(), "customer_acceptance")
    }

    func testEncoding() {
        let onlineParams = STPMandateOnlineParams(ipAddress: "", userAgent: "")
        onlineParams.inferFromClient = NSNumber(value: true)
        var params = STPMandateCustomerAcceptanceParams(type: .online, onlineParams: onlineParams)!

        var paramsAsDict = STPFormEncoder.dictionary(forObject: params)
        var expected = [
            "customer_acceptance": [
                "type": "online",
                "online": [
                    "infer_from_client": NSNumber(value: true)
                ],
            ],
        ]
        XCTAssertEqual(paramsAsDict as NSDictionary, expected as NSDictionary)

        params = STPMandateCustomerAcceptanceParams(type: .offline, onlineParams: nil)!
        paramsAsDict = STPFormEncoder.dictionary(forObject: params)
        expected = [
            "customer_acceptance": [
                "type": "offline"
            ],
        ]
        XCTAssertEqual(paramsAsDict as NSDictionary, expected as NSDictionary)
    }

    // MARK: - Decoding Tests

    func testDecodingOnlineType() {
        let json = [
            "type": "online",
            "online": [
                "ip_address": "127.0.0.1",
                "user_agent": "Mozilla/5.0",
            ],
        ] as [String: Any]

        let customerAcceptance = STPMandateCustomerAcceptanceParams.decodedObject(fromAPIResponse: json)

        XCTAssertNotNil(customerAcceptance)
        XCTAssertEqual(customerAcceptance?.type, .online)
        XCTAssertNotNil(customerAcceptance?.onlineParams)
        XCTAssertEqual(customerAcceptance?.onlineParams?.ipAddress, "127.0.0.1")
        XCTAssertEqual(customerAcceptance?.onlineParams?.userAgent, "Mozilla/5.0")
    }

    func testDecodingOfflineType() {
        let json = [
            "type": "offline"
        ] as [String: Any]

        let customerAcceptance = STPMandateCustomerAcceptanceParams.decodedObject(fromAPIResponse: json)

        XCTAssertNotNil(customerAcceptance)
        XCTAssertEqual(customerAcceptance?.type, .offline)
        XCTAssertNil(customerAcceptance?.onlineParams)
    }

    func testDecodingMissingType() {
        let jsonWithoutType = [
            "online": [
                "ip_address": "127.0.0.1",
                "user_agent": "Mozilla/5.0",
            ],
        ] as [String: Any]

        let customerAcceptance = STPMandateCustomerAcceptanceParams.decodedObject(fromAPIResponse: jsonWithoutType)
        XCTAssertNil(customerAcceptance, "decodedObject should return nil when 'type' field is missing")
    }

    func testDecodingNullType() {
        let jsonWithNullType = [
            "type": NSNull(),
            "online": [
                "ip_address": "127.0.0.1",
                "user_agent": "Mozilla/5.0",
            ],
        ] as [String: Any]

        let customerAcceptance = STPMandateCustomerAcceptanceParams.decodedObject(fromAPIResponse: jsonWithNullType)
        XCTAssertNil(customerAcceptance, "decodedObject should return nil when 'type' field is null")
    }

    func testDecodingInvalidType() {
        let jsonWithInvalidType = [
            "type": "invalid_type"
        ] as [String: Any]

        let customerAcceptance = STPMandateCustomerAcceptanceParams.decodedObject(fromAPIResponse: jsonWithInvalidType)
        XCTAssertNil(customerAcceptance, "decodedObject should return nil when 'type' field has invalid value")
    }

    func testDecodingEmptyType() {
        let jsonWithEmptyType = [
            "type": ""
        ] as [String: Any]

        let customerAcceptance = STPMandateCustomerAcceptanceParams.decodedObject(fromAPIResponse: jsonWithEmptyType)
        XCTAssertNil(customerAcceptance, "decodedObject should return nil when 'type' field is empty")
    }

    func testDecodingNilResponse() {
        let customerAcceptance = STPMandateCustomerAcceptanceParams.decodedObject(fromAPIResponse: nil)
        XCTAssertNil(customerAcceptance, "decodedObject should return nil for nil response")
    }

    func testDecodingOnlineWithoutOnlineParams() {
        let json = [
            "type": "online"
        ] as [String: Any]

        let customerAcceptance = STPMandateCustomerAcceptanceParams.decodedObject(fromAPIResponse: json)

        // Should still create the object even without online params, as they're optional in the response
        XCTAssertNotNil(customerAcceptance)
        XCTAssertEqual(customerAcceptance?.type, .online)
        XCTAssertNil(customerAcceptance?.onlineParams)
    }
}
