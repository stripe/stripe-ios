//
//  FinancialConnectionsAnalyticsTest.swift
//  StripeFinancialConnectionsTests
//
//  Created by Vardges Avetisyan on 12/9/21.
//

import XCTest

@_spi(STP) import StripeCore
@testable @_spi(STP) import StripeFinancialConnections

final class FinancialConnectionsSheetAnalyticsTest: XCTestCase {

    func testFinancialConnectionsSheetCompletionAnalyticCompleted() {
        let accountList = StripeAPI.FinancialConnectionsSession.AccountList(data: [], hasMore: false)
        let session = StripeAPI.FinancialConnectionsSession(
            clientSecret: "",
            id: "",
            accounts: accountList,
            livemode: false,
            paymentAccount: nil,
            bankAccountToken: nil,
            status: nil,
            statusDetails: nil
        )
        let analytic = FinancialConnectionsSheetCompletionAnalytic.make(
            linkAccountSessionId: "linkAccountSessionId",
            result: .completed(.financialConnections(session))
        )
        guard let closedAnalytic = analytic as? FinancialConnectionsSheetClosedAnalytic else {
            return XCTFail("Expected `FinancialConnectionsSheetClosedAnalytic`")
        }

        XCTAssertEqual(closedAnalytic.linkAccountSessionId, "linkAccountSessionId")
        XCTAssertEqual(closedAnalytic.result, "completed")
    }

    func testFinancialConnectionsSheetCompletionAnalyticCanceled() {
        let analytic = FinancialConnectionsSheetCompletionAnalytic.make(linkAccountSessionId: "linkAccountSessionId", result: .canceled)
        guard let closedAnalytic = analytic as? FinancialConnectionsSheetClosedAnalytic else {
            return XCTFail("Expected `FinancialConnectionsSheetClosedAnalytic`")
        }

        XCTAssertEqual(closedAnalytic.linkAccountSessionId, "linkAccountSessionId")
        XCTAssertEqual(closedAnalytic.result, "cancelled")
    }

    func testFinancialConnectionsSheetCompletionAnalyticFailed() {
        let analytic = FinancialConnectionsSheetCompletionAnalytic.make(
            linkAccountSessionId: "linkAccountSessionId",
            result: .failed(error: FinancialConnectionsSheetError.unknown(debugDescription: "some description"))
        )
        guard let failedAnalytic = analytic as? FinancialConnectionsSheetFailedAnalytic else {
            return XCTFail("Expected `FinancialConnectionsSheetFailedAnalytic`")
        }

        XCTAssertEqual(failedAnalytic.linkAccountSessionId, "linkAccountSessionId")
    }
}
