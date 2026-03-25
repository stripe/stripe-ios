//
//  STPTelemetryClientFunctionalTest.swift
//  StripeApplePayTests
//
//  Created by Yuki Tokuhiro on 5/21/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import XCTest

// swift-format-ignore
@testable @_spi(STP) import StripeCore

class STPTelemetryClientFunctionalTest: XCTestCase {
    override func setUp() async throws {
        STPTelemetryClient._forceShouldSendTelemetryInTests = true
    }

    func testSendFraudDetectionData() {
        // Sending telemetry without any FraudDetectionData...
        FraudDetectionData.shared.sid = nil
        FraudDetectionData.shared.sidCreationDate = nil
        FraudDetectionData.shared.muid = nil
        FraudDetectionData.shared.guid = nil
        let sendTelemetry1 = expectation(description: "")
        STPTelemetryClient.shared.sendTelemetryData { _ in
            sendTelemetry1.fulfill()
        }
        waitForExpectations(timeout: 10, handler: nil)
        // ...populates FraudDetectionData
        let sid = FraudDetectionData.shared.sid
        let muid = FraudDetectionData.shared.muid
        let guid = FraudDetectionData.shared.guid
        XCTAssertNotNil(sid)
        XCTAssertNotNil(muid)
        XCTAssertNotNil(guid)
        // ...and updates UserDefaults
        XCTAssertEqual(UserDefaults.standard.fraudDetectionData, FraudDetectionData.shared)

        let sendTelemetry2 = expectation(description: "")
        // Sending telemetry again...
        STPTelemetryClient.shared.sendTelemetryData { _ in
            sendTelemetry2.fulfill()
        }
        // ...gives the same FraudDetectionData
        XCTAssertEqual(FraudDetectionData.shared.sid, sid)
        XCTAssertEqual(FraudDetectionData.shared.muid, muid)
        XCTAssertEqual(FraudDetectionData.shared.guid, guid)
        XCTAssertEqual(UserDefaults.standard.fraudDetectionData, FraudDetectionData.shared) // make sure user defaults is set too
        guard let sidCreationDate = FraudDetectionData.shared.sidCreationDate else {
            XCTFail()
            return
        }
        // sanity check creation date looks right
        XCTAssertTrue(sidCreationDate > Date(timeIntervalSinceNow: -10))
        waitForExpectations(timeout: 10, handler: nil)

        // Expiring the FraudDetectionData
        FraudDetectionData.shared.sidCreationDate = Date(timeIntervalSinceNow: -999999)
        let sendTelemetry3 = expectation(description: "")
        // ...and sending telemetry again
        STPTelemetryClient.shared.sendTelemetryData { _ in
            sendTelemetry3.fulfill()
        }
        waitForExpectations(timeout: 10, handler: nil)
        // ...gives the same muid and guid but different sid
        XCTAssertEqual(FraudDetectionData.shared.muid, muid)
        XCTAssertEqual(FraudDetectionData.shared.guid, guid)
        XCTAssertNotEqual(FraudDetectionData.shared.sid, sid)
        XCTAssertEqual(UserDefaults.standard.fraudDetectionData, FraudDetectionData.shared) // make sure user defaults is set too
    }
}
