//
//  FinancialConnectionsSessionTests.swift
//  StripeFinancialConnectionsTests
//
//  Created by Vardges Avetisyan on 4/29/22.
//

import Foundation
import StripeCoreTestUtils
@testable import StripeFinancialConnections
import XCTest

enum FinancialConnectionsSessionMock: String, MockData {
    typealias ResponseType = StripeAPI.FinancialConnectionsSession
    var bundle: Bundle { return Bundle(for: ClassForBundle.self) }

    case bothAccountsAndLinkedAccountsPresent = "FinancialConnectionsSession_both_accounts_la"
    case onlyAccountsPresent = "FinancialConnectionsSession_only_accounts"
    case bothAccountsAndLinkedAccountsMissing = "FinancialConnectionsSession_only_both_missing"
    case onlyLinkedAccountsPresent = "FinancialConnectionsSession_only_la"
}

// Dummy class to determine this bundle
private class ClassForBundle { }

final class FinancialConnectionsSessionTests: XCTestCase {

    func testBothAccountsAndLinkedAccountsPresentFavorsAccounts() {
        guard let session = try? FinancialConnectionsSessionMock.bothAccountsAndLinkedAccountsPresent.make() else {
            return XCTFail("Could not load FinancialConnectionsSession")
        }
        XCTAssertEqual(session.accounts.data.count, 5)
    }

    func testOnlyAccountsPresentParsesCorrectly() {
        guard let session = try? FinancialConnectionsSessionMock.onlyAccountsPresent.make() else {
            return XCTFail("Could not load FinancialConnectionsSession")
        }
        XCTAssertEqual(session.accounts.data.count, 5)
    }

    func testOnlyLinkedAccountsPresentParsesCorrectly() {
        guard let session = try? FinancialConnectionsSessionMock.onlyLinkedAccountsPresent.make() else {
            return XCTFail("Could not load FinancialConnectionsSession")
        }
        XCTAssertEqual(session.accounts.data.count, 5)
    }

    func testBothAccountsAndLinkedAccountsMissingFailsToParse() {
        XCTAssertThrowsError(try FinancialConnectionsSessionMock.bothAccountsAndLinkedAccountsMissing.make())
    }

}
