//
//  FraudDetectionDataTest.swift
//  StripeiOS Tests
//
//  Created by Yuki Tokuhiro on 5/21/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import XCTest

@testable@_spi(STP) import Stripe
@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePayments
@testable@_spi(STP) import StripePaymentSheet
@testable@_spi(STP) import StripePaymentsUI

class FraudDetectionDataTest: XCTestCase {
    func testResetsSIDIfExpired() {
        FraudDetectionData.shared.sidCreationDate = Date(timeInterval: -30 * 60 - 1, since: Date())
        FraudDetectionData.shared.resetSIDIfExpired()
        XCTAssertNil(FraudDetectionData.shared.sid)
    }

    func testSIDNotExpired() {
        // Test resets sid if expired
        FraudDetectionData.shared.sid = "123"
        FraudDetectionData.shared.sidCreationDate = Date()
        FraudDetectionData.shared.resetSIDIfExpired()
        XCTAssertNotNil(FraudDetectionData.shared.sid)
    }
}
