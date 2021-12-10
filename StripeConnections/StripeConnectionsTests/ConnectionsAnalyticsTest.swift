//
//  ConnectionsAnalyticsTest.swift
//  StripeConnectionsTests
//
//  Created by Vardges Avetisyan on 12/9/21.
//

import XCTest

@testable import StripeConnections
@_spi(STP) import StripeCore

@available(iOS 12, *)
final class ConnectionsSheetAnalyticsTest: XCTestCase {

    func testConnectionsSheetFailedAnalyticEncoding() {
        let analytic = ConnectionsSheetFailedAnalytic(clientSecret: "test", error: ConnectionsSheetError.unknown(debugDescription: "some description"))
        XCTAssertNotNil(analytic.error)

        let errorDict = analytic.error.serializeForLogging()
        XCTAssertNil(errorDict["user_info"])
        XCTAssertEqual(errorDict["code"] as? Int, 0)
        XCTAssertEqual(errorDict["domain"] as? String, "Stripe.ConnectionsSheetError")
    }

    func testConnectionsSheetCompletionAnalyticCompleted() {
        let analytic = ConnectionsSheetCompletionAnalytic.make(clientSecret: "secret", result: .completed(linkedAccounts: []))
        guard let closedAnalytic = analytic as? ConnectionsSheetClosedAnalytic else {
            return XCTFail("Expected `ConnectionsSheetClosedAnalytic`")
        }

        XCTAssertEqual(closedAnalytic.clientSecret, "secret")
        XCTAssertEqual(closedAnalytic.result, "completed")
    }

    func testConnectionsSheetCompletionAnalyticCanceled() {
        let analytic = ConnectionsSheetCompletionAnalytic.make(clientSecret: "secret", result: .canceled)
        guard let closedAnalytic = analytic as? ConnectionsSheetClosedAnalytic else {
            return XCTFail("Expected `ConnectionsSheetClosedAnalytic`")
        }

        XCTAssertEqual(closedAnalytic.clientSecret, "secret")
        XCTAssertEqual(closedAnalytic.result, "cancelled")
    }

    func testConnectionsSheetCompletionAnalyticFailed() {
        let analytic = ConnectionsSheetCompletionAnalytic.make(clientSecret: "secret", result: .failed(error: ConnectionsSheetError.unknown(debugDescription: "some description")))
        guard let failedAnalytic = analytic as? ConnectionsSheetFailedAnalytic else {
            return XCTFail("Expected `ConnectionsSheetFailedAnalytic`")
        }

        XCTAssertEqual(failedAnalytic.clientSecret, "secret")
        XCTAssert(failedAnalytic.error is ConnectionsSheetError)
    }
}
