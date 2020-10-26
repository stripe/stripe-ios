//
//  STPTelemetryClientTest.swift
//  StripeiOS Tests
//
//  Created by Yuki Tokuhiro on 9/24/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import XCTest

@testable import Stripe

class STPTelemetryClientTest: XCTestCase {

  func testAddTelemetryData() {
    let sut = STPTelemetryClient.sharedInstance()
    var params: [String: Any] = [
      "foo": "bar"
    ]
    let exp = expectation(description: "delay")
    DispatchQueue.main.asyncAfter(
      deadline: DispatchTime.now() + Double(Int64(0.1 * Double(NSEC_PER_SEC)))
        / Double(NSEC_PER_SEC),
      execute: {
        sut.addTelemetryFields(toParams: &params)
        XCTAssertNotNil(params)
        exp.fulfill()
      })
    waitForExpectations(timeout: 2, handler: nil)
  }

  func testAdvancedFraudSignalsSwitch() {
    XCTAssertTrue(StripeAPI.advancedFraudSignalsEnabled)
    StripeAPI.advancedFraudSignalsEnabled = false
    XCTAssertFalse(StripeAPI.advancedFraudSignalsEnabled)
  }

}
