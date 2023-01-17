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
}
