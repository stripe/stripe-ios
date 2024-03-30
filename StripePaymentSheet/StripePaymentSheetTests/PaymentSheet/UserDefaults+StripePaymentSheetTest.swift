//
//  UserDefaults+StripePaymentSheetTest.swift
//  StripePaymentSheetTests
//
//  Created by David Estes on 1/22/24.
//

import Foundation

import XCTest

@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePaymentSheet

class UserDefaults_StripePaymentSheetTest: XCTestCase {

    func testCustomerToLastSelectedPaymentMethod() throws {
        let userDefaults = UserDefaults(suiteName: #file)!
        userDefaults.removePersistentDomain(forName: #file)

        let c = [UUID().uuidString: UUID().uuidString]
        userDefaults.customerToLastSelectedPaymentMethod = c
        XCTAssertEqual(userDefaults.customerToLastSelectedPaymentMethod, c)
    }

    func testUsedLink() throws {
        let userDefaults = UserDefaults(suiteName: #file)!
        userDefaults.removePersistentDomain(forName: #file)

        XCTAssertFalse(userDefaults.customerHasUsedLink)
        userDefaults.markLinkAsUsed()
        XCTAssertTrue(userDefaults.customerHasUsedLink)
        userDefaults.clearLinkDefaults()
        XCTAssertFalse(userDefaults.customerHasUsedLink)
    }
}
