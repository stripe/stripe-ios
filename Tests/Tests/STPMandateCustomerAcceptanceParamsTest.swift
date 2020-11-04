//
//  STPMandateCustomerAcceptanceParamsTest.swift
//  StripeiOS Tests
//
//  Created by Cameron Sabol on 10/18/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//
@testable import Stripe

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
      ]
    ]
    XCTAssertEqual(paramsAsDict as NSDictionary, expected as NSDictionary)

    params = STPMandateCustomerAcceptanceParams(type: .offline, onlineParams: nil)!
    paramsAsDict = STPFormEncoder.dictionary(forObject: params)
    expected = [
      "customer_acceptance": [
        "type": "offline"
      ]
    ]
    XCTAssertEqual(paramsAsDict as NSDictionary, expected as NSDictionary)
  }
}
