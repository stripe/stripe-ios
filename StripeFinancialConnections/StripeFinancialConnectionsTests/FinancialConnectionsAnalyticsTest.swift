//
//  FinancialConnectionsAnalyticsTest.swift
//  StripeFinancialConnectionsTests
//
//  Created by Vardges Avetisyan on 12/9/21.
//

import XCTest

@testable import StripeFinancialConnections
@_spi(STP) import StripeCore

final class FinancialConnectionsSheetAnalyticsTest: XCTestCase {

    func testFinancialConnectionsSheetFailedAnalyticEncoding() {
        let analytic = FinancialConnectionsSheetFailedAnalytic(clientSecret: "test", error: FinancialConnectionsSheetError.unknown(debugDescription: "some description"))
        XCTAssertNotNil(analytic.error)

        let errorDict = analytic.error.serializeForLogging()
        XCTAssertNil(errorDict["user_info"])
        XCTAssertEqual(errorDict["code"] as? Int, 0)
        XCTAssertEqual(errorDict["domain"] as? String, "Stripe.FinancialConnectionsSheetError")
    }

    func testFinancialConnectionsSheetCompletionAnalyticCompleted() {
        let accountList = StripeAPI.FinancialConnectionsSession.AccountList(data: [], hasMore: false)
        let session = StripeAPI.FinancialConnectionsSession(clientSecret: "", id: "", accounts: accountList, livemode: false, paymentAccount: nil, bankAccountToken: nil)
        let analytic = FinancialConnectionsSheetCompletionAnalytic.make(clientSecret: "secret", result: .completed(session: session))
        guard let closedAnalytic = analytic as? FinancialConnectionsSheetClosedAnalytic else {
            return XCTFail("Expected `FinancialConnectionsSheetClosedAnalytic`")
        }

        XCTAssertEqual(closedAnalytic.clientSecret, "secret")
        XCTAssertEqual(closedAnalytic.result, "completed")
    }

    func testFinancialConnectionsSheetCompletionAnalyticCanceled() {
        let analytic = FinancialConnectionsSheetCompletionAnalytic.make(clientSecret: "secret", result: .canceled)
        guard let closedAnalytic = analytic as? FinancialConnectionsSheetClosedAnalytic else {
            return XCTFail("Expected `FinancialConnectionsSheetClosedAnalytic`")
        }

        XCTAssertEqual(closedAnalytic.clientSecret, "secret")
        XCTAssertEqual(closedAnalytic.result, "cancelled")
    }

    func testFinancialConnectionsSheetCompletionAnalyticFailed() {
        let analytic = FinancialConnectionsSheetCompletionAnalytic.make(clientSecret: "secret", result: .failed(error: FinancialConnectionsSheetError.unknown(debugDescription: "some description")))
        guard let failedAnalytic = analytic as? FinancialConnectionsSheetFailedAnalytic else {
            return XCTFail("Expected `FinancialConnectionsSheetFailedAnalytic`")
        }

        XCTAssertEqual(failedAnalytic.clientSecret, "secret")
        XCTAssert(failedAnalytic.error is FinancialConnectionsSheetError)
    }
}
