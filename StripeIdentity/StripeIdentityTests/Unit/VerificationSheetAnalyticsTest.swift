//
//  VerificationSheetAnalyticsTest.swift
//  StripeIdentityTests
//
//  Created by Mel Ludowise on 3/12/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import XCTest

@testable import StripeIdentity
@_spi(STP) import StripeCore

final class VerificationSheetAnalyticsTest: XCTestCase {

    func testVerificationSheetFailedAnalyticEncoding() {
        let analytic = VerificationSheetFailedAnalytic(verificationSessionId: nil, error: IdentityVerificationSheetError.unknown(debugDescription: "some description"))
        XCTAssertNotNil(analytic.error)

        let errorDict = analytic.error.serializeForLogging()
        XCTAssertNil(errorDict["user_info"])
        XCTAssertEqual(errorDict["code"] as? Int, 1)
        XCTAssertEqual(errorDict["domain"] as? String, "StripeIdentity.IdentityVerificationSheetError")
    }

    func testVerificationSheetCompletionAnalyticCompleted() {
        let analytic = VerificationSheetCompletionAnalytic.make(verificationSessionId: "session_id", sessionResult: .flowCompleted)
        guard let closedAnalytic = analytic as? VerificationSheetClosedAnalytic else {
            return XCTFail("Expected `VerificationSheetClosedAnalytic`")
        }

        XCTAssertEqual(closedAnalytic.verificationSessionId, "session_id")
        XCTAssertEqual(closedAnalytic.sessionResult, "flow_completed")
    }

    func testVerificationSheetCompletionAnalyticCanceled() {
        let analytic = VerificationSheetCompletionAnalytic.make(verificationSessionId: "session_id", sessionResult: .flowCanceled)
        guard let closedAnalytic = analytic as? VerificationSheetClosedAnalytic else {
            return XCTFail("Expected `VerificationSheetClosedAnalytic`")
        }

        XCTAssertEqual(closedAnalytic.verificationSessionId, "session_id")
        XCTAssertEqual(closedAnalytic.sessionResult, "flow_canceled")
    }

    func testVerificationSheetCompletionAnalyticFailed() {
        let analytic = VerificationSheetCompletionAnalytic.make(verificationSessionId: "session_id", sessionResult: .flowFailed(error: IdentityVerificationSheetError.unknown(debugDescription: "some description")))
        guard let failedAnalytic = analytic as? VerificationSheetFailedAnalytic else {
            return XCTFail("Expected `VerificationSheetFailedAnalytic`")
        }

        XCTAssertEqual(failedAnalytic.verificationSessionId, "session_id")
        XCTAssert(failedAnalytic.error is IdentityVerificationSheetError)
    }
}
