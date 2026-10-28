//
//  STPRadarSessionFunctionalTest.swift
//  StripeiOS Tests
//
//  Created by Yuki Tokuhiro on 5/20/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import XCTest

@testable@_spi(InternalOnlyAPI) import Stripe
@testable@_spi(InternalOnlyAPI) import StripeCore
@testable@_spi(InternalOnlyAPI) import StripePayments
@testable@_spi(InternalOnlyAPI) import StripePaymentSheet
import StripePaymentsTestUtils
@testable@_spi(InternalOnlyAPI) import StripePaymentsUI

class STPRadarSessionFunctionalTest: XCTestCase {
    func testCreateWithoutInitialFraudDetection() {
        // When fraudDetectionData is empty...
        FraudDetectionData.shared.reset()

        let client = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)
        let exp1 = expectation(description: "Create RadarSession")
        client.createRadarSession { session, error in
            // ...creates a Radar Session
            XCTAssertNil(error)
            guard let session = session else {
                XCTFail()
                return
            }
            XCTAssertTrue(session.id.count > 0)
            exp1.fulfill()
        }

        waitForExpectations(timeout: 10, handler: nil)

        // Now that fraudDetectionData is populated...
        XCTAssertNotNil(FraudDetectionData.shared.sid)
        XCTAssertNotNil(FraudDetectionData.shared.muid)
        XCTAssertNotNil(FraudDetectionData.shared.guid)

        let exp2 = expectation(description: "Create RadarSession again")
        client.createRadarSession { session, error in
            // ...still creates a Radar Session
            XCTAssertNil(error)
            guard let session = session else {
                XCTFail()
                return
            }
            XCTAssertTrue(session.id.count > 0)
            exp2.fulfill()
        }

        waitForExpectations(timeout: 10, handler: nil)
    }
}
