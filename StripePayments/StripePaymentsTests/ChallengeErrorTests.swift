//
//  ChallengeErrorTests.swift
//  StripePaymentsTests
//

import XCTest

@_spi(STP) @testable import StripePayments

class ChallengeErrorTests: XCTestCase {

    // MARK: - analyticsErrorType

    func testWebErrorAnalyticsTypeUsesProvidedType() {
        let error = ChallengeError.webError(message: "msg", type: "arkose_error", code: "1234")
        XCTAssertEqual(error.analyticsErrorType, "arkose_error")
    }

    func testNonWebErrorsUseDefaultAnalyticsType() {
        let underlying = NSError(domain: "test", code: 1)
        XCTAssertEqual(ChallengeError.userCanceled.analyticsErrorType, "IntentConfirmationChallengeError")
        XCTAssertEqual(ChallengeError.unknownError.analyticsErrorType, "IntentConfirmationChallengeError")
        XCTAssertEqual(ChallengeError.navigationFailed(underlying).analyticsErrorType, "IntentConfirmationChallengeError")
    }

    // MARK: - analyticsErrorCode

    func testWebErrorAnalyticsCodeUsesProvidedCode() {
        let error = ChallengeError.webError(message: "msg", type: "type", code: "MY_CODE")
        XCTAssertEqual(error.analyticsErrorCode, "MY_CODE")
    }

    func testWebErrorAnalyticsCodeNilDefaultsToUnknown() {
        let error = ChallengeError.webError(message: "msg", type: "type", code: nil)
        XCTAssertEqual(error.analyticsErrorCode, "unknown")
    }

    // MARK: - additionalNonPIIErrorDetails

    func testWebErrorAdditionalDetailsHasFromBridgeTrue() {
        let error = ChallengeError.webError(message: "msg", type: "type", code: nil)
        XCTAssertEqual(error.additionalNonPIIErrorDetails["from_bridge"] as? Bool, true)
    }

    func testNonWebErrorsAdditionalDetailsHaveFromBridgeFalse() {
        let underlying = NSError(domain: "test", code: 1)
        XCTAssertEqual(ChallengeError.userCanceled.additionalNonPIIErrorDetails["from_bridge"] as? Bool, false)
        XCTAssertEqual(ChallengeError.unknownError.additionalNonPIIErrorDetails["from_bridge"] as? Bool, false)
        XCTAssertEqual(ChallengeError.navigationFailed(underlying).additionalNonPIIErrorDetails["from_bridge"] as? Bool, false)
    }

    // MARK: - errorDescription

    func testWebErrorDescriptionUsesMessage() {
        let error = ChallengeError.webError(message: "Captcha verification failed", type: "type", code: nil)
        XCTAssertEqual(error.errorDescription, "Captcha verification failed")
    }

    func testNavigationFailedDescriptionIncludesUnderlyingError() {
        let underlying = NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Connection lost"])
        let error = ChallengeError.navigationFailed(underlying)
        XCTAssertEqual(error.errorDescription, "Navigation failed: Connection lost")
    }

    func testUserCanceledDescriptionIsNil() {
        XCTAssertNil(ChallengeError.userCanceled.errorDescription)
    }

    func testUnknownErrorHasDescription() {
        XCTAssertEqual(ChallengeError.unknownError.errorDescription, "Unknown error.")
    }
}
