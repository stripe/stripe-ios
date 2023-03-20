//
//  STPTelemetryClientTest.swift
//  StripeiOS Tests
//
//  Created by Yuki Tokuhiro on 9/24/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import XCTest

@testable @_spi(STP) import StripeApplePay

class STPTelemetryClientTest: XCTestCase {

    func testAddTelemetryData() {
        let sut = STPTelemetryClient.shared
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

    func testAddTelemetryFieldsWhenFraudDetectionDataEmpty() {
        // Should not add any fields if fraudDetectionData is empty
        FraudDetectionData.shared.reset()
        var params: [String: Any] = [:]
        STPTelemetryClient.shared.addTelemetryFields(toParams: &params)
        XCTAssertTrue(params.isEmpty)
    }

    func testAddTelemetryFieldsWhenSIDExpired() {
        // Should add muid, but not add sid if it's expired
        var params: [String: Any] = [:]
        FraudDetectionData.shared.sid = "expired"
        FraudDetectionData.shared.sidCreationDate = Date(timeInterval: -30 * 60, since: Date())
        FraudDetectionData.shared.muid = "muid value"
        FraudDetectionData.shared.guid = "guid value"
        STPTelemetryClient.shared.addTelemetryFields(toParams: &params)
        XCTAssertEqual(params["muid"] as? String, "muid value")
        XCTAssertEqual(params["guid"] as? String, "guid value")
        XCTAssertNil(params["sid"] as? String)
    }

    func testAddTelemetryFields() {
        var params: [String: Any] = [:]
        FraudDetectionData.shared.sid = "sid value"
        FraudDetectionData.shared.muid = "muid value"
        FraudDetectionData.shared.guid = "guid value"
        FraudDetectionData.shared.sidCreationDate = Date()
        STPTelemetryClient.shared.addTelemetryFields(toParams: &params)
        XCTAssertEqual(params["muid"] as? String, "muid value")
        XCTAssertEqual(params["sid"] as? String, "sid value")
        XCTAssertEqual(params["guid"] as? String, "guid value")
    }
}
