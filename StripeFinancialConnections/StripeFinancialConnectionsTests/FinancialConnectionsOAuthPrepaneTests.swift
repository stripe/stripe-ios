//
//  FinancialConnectionsOAuthPrepaneTests.swift
//  StripeFinancialConnectionsTests
//

import Foundation
@_spi(STP) @testable import StripeCore
import StripeCoreTestUtils
@testable import StripeFinancialConnections
import XCTest

enum FinancialConnectionsOAuthPrepaneMock: String, MockData {
    typealias ResponseType = FinancialConnectionsOAuthPrepane
    var bundle: Bundle { return Bundle(for: ClassForBundle.self) }

    case withDataAccessNotice = "FinancialConnectionsOAuthPrepane_with_data_access_notice"
    case withoutDataAccessNotice = "FinancialConnectionsOAuthPrepane_without_data_access_notice"
}

// Dummy class to determine this bundle
private class ClassForBundle {}

final class FinancialConnectionsOAuthPrepaneTests: XCTestCase {

    func testDecodesDataAccessNoticeWhenPresent() throws {
        let prepane = try FinancialConnectionsOAuthPrepaneMock.withDataAccessNotice.make()

        XCTAssertEqual(prepane.title, "Connect your account")
        XCTAssertEqual(prepane.dataAccessNotice?.title, "Data sharing")
        XCTAssertEqual(prepane.dataAccessNotice?.cta, "OK")
        XCTAssertEqual(prepane.dataAccessNotice?.body.bullets.count, 1)
    }

    func testDecodesWithoutDataAccessNotice() throws {
        let prepane = try FinancialConnectionsOAuthPrepaneMock.withoutDataAccessNotice.make()

        XCTAssertEqual(prepane.title, "Connect your account")
        XCTAssertNil(prepane.dataAccessNotice)
    }
}
