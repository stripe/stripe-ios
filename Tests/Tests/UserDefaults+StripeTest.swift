//
//  UserDefaults+StripeTest.swift
//  StripeiOS Tests
//
//  Created by Yuki Tokuhiro on 5/21/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import XCTest
@testable import Stripe
@testable @_spi(STP) import StripeApplePay

class UserDefaults_StripeTest: XCTestCase {
    func testFraudDetectionData() throws {
        let fraudDetectionData = FraudDetectionData(sid: UUID().uuidString, muid: UUID().uuidString, guid: UUID().uuidString, sidCreationDate: Date())
        UserDefaults.standard.fraudDetectionData = fraudDetectionData
        XCTAssertEqual(UserDefaults.standard.fraudDetectionData, fraudDetectionData)
    }

    func testCustomerToLastSelectedPaymentMethod() throws {
        let c = [UUID().uuidString: UUID().uuidString]
        UserDefaults.standard.customerToLastSelectedPaymentMethod = c
        XCTAssertEqual(UserDefaults.standard.customerToLastSelectedPaymentMethod, c)
    }
}
