//
//  STPMandateDataParamsTest.swift
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

class STPMandateDataParamsTest: XCTestCase {
    func testRootObjectName() {
        XCTAssertEqual(STPMandateDataParams.rootObjectName(), "mandate_data")
    }

    func testEncoding() {
        let onlineParams = STPMandateOnlineParams(ipAddress: "", userAgent: "")
        onlineParams.inferFromClient = NSNumber(value: true)
        let customerAcceptanceParams = STPMandateCustomerAcceptanceParams(
            type: .online,
            onlineParams: onlineParams
        )!

        let params = STPMandateDataParams(customerAcceptance: customerAcceptanceParams)

        let paramsAsDict = STPFormEncoder.dictionary(forObject: params)
        let expected = [
            "mandate_data": [
                "customer_acceptance": [
                    "type": "online",
                    "online": [
                        "infer_from_client": true
                    ],
                ],
            ],
        ]
        XCTAssertEqual(paramsAsDict as NSDictionary, expected as NSDictionary)
    }
    
    // MARK: - Decoding Tests
    
    func testDecodingValidMandateData() {
        let json = [
            "customer_acceptance": [
                "type": "online",
                "online": [
                    "ip_address": "127.0.0.1",
                    "user_agent": "Mozilla/5.0"
                ]
            ]
        ] as [String: Any]
        
        let mandateData = STPMandateDataParams.decodedObject(fromAPIResponse: json)
        
        XCTAssertNotNil(mandateData)
        XCTAssertEqual(mandateData?.customerAcceptance.type, .online)
        XCTAssertEqual(mandateData?.customerAcceptance.onlineParams?.ipAddress, "127.0.0.1")
        XCTAssertEqual(mandateData?.customerAcceptance.onlineParams?.userAgent, "Mozilla/5.0")
    }
    
    func testDecodingMissingCustomerAcceptance() {
        let jsonWithoutCustomerAcceptance = [:] as [String: Any]
        
        let mandateData = STPMandateDataParams.decodedObject(fromAPIResponse: jsonWithoutCustomerAcceptance)
        XCTAssertNil(mandateData, "decodedObject should return nil when customer_acceptance is missing")
    }
    
    func testDecodingNullCustomerAcceptance() {
        let jsonWithNullCustomerAcceptance = [
            "customer_acceptance": NSNull()
        ] as [String: Any]
        
        let mandateData = STPMandateDataParams.decodedObject(fromAPIResponse: jsonWithNullCustomerAcceptance)
        XCTAssertNil(mandateData, "decodedObject should return nil when customer_acceptance is null")
    }
    
    func testDecodingInvalidCustomerAcceptance() {
        let jsonWithInvalidCustomerAcceptance = [
            "customer_acceptance": "invalid_string"
        ] as [String: Any]
        
        let mandateData = STPMandateDataParams.decodedObject(fromAPIResponse: jsonWithInvalidCustomerAcceptance)
        XCTAssertNil(mandateData, "decodedObject should return nil when customer_acceptance is not a dictionary")
    }
    
    func testDecodingNilResponse() {
        let mandateData = STPMandateDataParams.decodedObject(fromAPIResponse: nil)
        XCTAssertNil(mandateData, "decodedObject should return nil for nil response")
    }
}
