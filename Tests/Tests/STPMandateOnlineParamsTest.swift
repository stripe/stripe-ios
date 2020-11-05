//
//  STPMandateOnlineParamsTest.swift
//  StripeiOS Tests
//
//  Created by Cameron Sabol on 10/18/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//
@testable import Stripe

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
      ]
    ]
    XCTAssertEqual(paramsAsDict as NSDictionary, expected as NSDictionary)

    params = STPMandateOnlineParams(ipAddress: "", userAgent: "")
    params.inferFromClient = NSNumber(value: true)
    paramsAsDict = STPFormEncoder.dictionary(forObject: params)
    expected = [
      "online": [
        "infer_from_client": NSNumber(value: true)
      ]
    ]
    XCTAssertEqual(paramsAsDict as NSDictionary, expected as NSDictionary)
  }
}
