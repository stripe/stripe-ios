//
//  FinancialConnectionsSessionTests.swift
//  StripeFinancialConnectionsTests
//
//  Created by Vardges Avetisyan on 4/29/22.
//

import Foundation
@_spi(STP) import StripeCore
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
    case relink = "FinancialConnectionsSession_relink"
    case relinkOptionsOnly = "FinancialConnectionsSession_relink_options_only"
}

enum FinancialConnectionsSynchronizeMock: String, MockData {
    typealias ResponseType = FinancialConnectionsSynchronize
    var bundle: Bundle { return Bundle(for: ClassForBundle.self) }

    case synchronize = "FinancialConnectionsSynchronize"
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

    func testRelinkFieldsParseWhenRelinkResultPresent() throws {
        let session = try FinancialConnectionsSessionMock.relink.make()

        XCTAssertEqual(session.relinkOptions?.authorization, "fcauth_123")
        XCTAssertEqual(session.relinkOptions?.account, "fca_1KtwJsdsdfdsf")
        XCTAssertEqual(session.relinkResult?.authorization, "fcauth_123")
        XCTAssertEqual(session.relinkResult?.account, "fca_1KtwJsdsdfdsf")
        XCTAssertNil(session.relinkResult?.failureReason)
    }

    func testRelinkFieldsAreNilWhenOnlyRelinkOptionsPresent() throws {
        let session = try FinancialConnectionsSessionMock.relinkOptionsOnly.make()

        XCTAssertNil(session.relinkOptions)
        XCTAssertNil(session.relinkResult)
    }

    func testRelinkFailureReasonParsesKnownValues() throws {
        XCTAssertEqual(
            try makeSession(withFailureReason: "no_account").relinkResult?.failureReason,
            .noAccount
        )
        XCTAssertEqual(
            try makeSession(withFailureReason: "no_authorization").relinkResult?.failureReason,
            .noAuthorization
        )
        XCTAssertEqual(
            try makeSession(withFailureReason: "other").relinkResult?.failureReason,
            .other
        )
    }

    private func makeSession(withFailureReason failureReason: String) throws -> StripeAPI.FinancialConnectionsSession {
        let json = """
        {
          "id": "fcsess_relink",
          "object": "link_account_session",
          "client_secret": "las_client_secrettest_tests",
          "accounts": {
            "object": "list",
            "data": [],
            "has_more": false,
            "total_count": 0,
            "url": "/v1/linked_accounts"
          },
          "livemode": false,
          "relink_options": {
            "authorization": "fcauth_123",
            "account": "fca_1KtwJsdsdfdsf"
          },
          "relink_result": {
            "authorization": null,
            "account": null,
            "failure_reason": "\(failureReason)"
          }
        }
        """

        return try StripeJSONDecoder().decode(
            StripeAPI.FinancialConnectionsSession.self,
            from: Data(json.utf8)
        )
    }
}
