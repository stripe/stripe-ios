//
//  FinancialConnectionsSessionTests.swift
//  StripeFinancialConnectionsTests
//
//  Created by Vardges Avetisyan on 4/29/22.
//

import CustomDump
import Foundation
@testable import StripeCore
import StripeCoreTestUtils
@testable @_spi(STP) import StripeFinancialConnections
import XCTest

enum FinancialConnectionsSessionMock: String, MockData {
    typealias ResponseType = StripeAPI.FinancialConnectionsSession
    var bundle: Bundle { return Bundle(for: ClassForBundle.self) }

    case bothAccountsAndLinkedAccountsPresent = "FinancialConnectionsSession_both_accounts_la"
    case onlyAccountsPresent = "FinancialConnectionsSession_only_accounts"
    case bothAccountsAndLinkedAccountsMissing = "FinancialConnectionsSession_only_both_missing"
    case onlyLinkedAccountsPresent = "FinancialConnectionsSession_only_la"
    case allFields = "FinancialConnectionsSession_all_account_fields"
}

// Dummy class to determine this bundle
private class ClassForBundle {}

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

    /// Validates that FinancialConnectionsSession encodes to a format StripeJS can use
    func testEncodeToJSFormat() throws {
        let parseableMocks: [FinancialConnectionsSessionMock] = [
            .bothAccountsAndLinkedAccountsPresent,
            .onlyAccountsPresent,
            .onlyLinkedAccountsPresent,
            .allFields
        ]
        try parseableMocks.forEach { sessionMock in
            let session = try sessionMock.make()
            let encodedAccounts = try session
                .accounts
                .encodeJSONDictionary()["data"] as? [NSDictionary]
            let encodedBankToken = try session
                .bankAccountToken?
                .encodeJSONDictionary() as? NSDictionary

            // Load expected
            let expectedDict = try XCTUnwrap(
                try JSONSerialization.jsonObject(
                    with: try Data(
                        contentsOf: sessionMock.bundle.url(
                            forResource: sessionMock.rawValue + "_encodedJS",
                            withExtension: "json"
                        )!
                    )
                ) as? NSDictionary
            )

            expectNoDifference(
                encodedAccounts,
                expectedDict["accounts"] as? [NSDictionary],
                sessionMock.rawValue
            )
            expectNoDifference(
                encodedBankToken,
                expectedDict["bank_account_token"] as? NSDictionary,
                sessionMock.rawValue
            )
        }
    }
}
