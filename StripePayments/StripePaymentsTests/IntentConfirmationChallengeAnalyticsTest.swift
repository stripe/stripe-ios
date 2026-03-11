//
//  IntentConfirmationChallengeAnalyticsTest.swift
//  StripePaymentsTests
//

import Foundation
import XCTest

@_spi(STP) @testable import StripeCore
@_spi(STP) @testable import StripePayments

class IntentConfirmationChallengeAnalyticsTest: XCTestCase {

    func testChallengeStartAnalyticsIncludesCaptchaVendorName() {
        let analyticsClient = STPAnalyticsClient()
        analyticsClient.logIntentConfirmationChallengeStart(captchaVendorName: "arkose")

        let payload = analyticsClient._testLogHistory.last
        XCTAssertEqual(payload?["event"] as? String, "elements.intent_confirmation_challenge.start")
        XCTAssertEqual(payload?["captcha_vendor_name"] as? String, "arkose")
    }

    func testChallengeStartAnalyticsExcludesCaptchaVendorNameWhenNil() {
        let analyticsClient = STPAnalyticsClient()
        analyticsClient.logIntentConfirmationChallengeStart(captchaVendorName: nil)

        let payload = analyticsClient._testLogHistory.last
        XCTAssertEqual(payload?["event"] as? String, "elements.intent_confirmation_challenge.start")
        XCTAssertNil(payload?["captcha_vendor_name"])
    }

    func testChallengeWebViewLoadedAnalyticsIncludesCaptchaVendorName() {
        let analyticsClient = STPAnalyticsClient()
        analyticsClient.logIntentConfirmationChallengeWebViewLoaded(duration: 1.5, captchaVendorName: "arkose")

        let payload = analyticsClient._testLogHistory.last
        XCTAssertEqual(payload?["event"] as? String, "elements.intent_confirmation_challenge.web_view_loaded")
        XCTAssertEqual(payload?["captcha_vendor_name"] as? String, "arkose")
        XCTAssertEqual(payload?["duration"] as? Double, 1500.0)
    }

    func testChallengeWebViewLoadedAnalyticsExcludesCaptchaVendorNameWhenNil() {
        let analyticsClient = STPAnalyticsClient()
        analyticsClient.logIntentConfirmationChallengeWebViewLoaded(duration: 1.5, captchaVendorName: nil)

        let payload = analyticsClient._testLogHistory.last
        XCTAssertEqual(payload?["event"] as? String, "elements.intent_confirmation_challenge.web_view_loaded")
        XCTAssertNil(payload?["captcha_vendor_name"])
        XCTAssertEqual(payload?["duration"] as? Double, 1500.0)
    }

    func testChallengeSuccessAnalyticsIncludesCaptchaVendorName() {
        let analyticsClient = STPAnalyticsClient()
        analyticsClient.logIntentConfirmationChallengeSuccess(duration: 1.5, captchaVendorName: "arkose")

        let payload = analyticsClient._testLogHistory.last
        XCTAssertEqual(payload?["event"] as? String, "elements.intent_confirmation_challenge.success")
        XCTAssertEqual(payload?["captcha_vendor_name"] as? String, "arkose")
        XCTAssertEqual(payload?["duration"] as? Double, 1500.0)
    }

    func testChallengeSuccessAnalyticsExcludesCaptchaVendorNameWhenNil() {
        let analyticsClient = STPAnalyticsClient()
        analyticsClient.logIntentConfirmationChallengeSuccess(duration: 1.5, captchaVendorName: nil)

        let payload = analyticsClient._testLogHistory.last
        XCTAssertEqual(payload?["event"] as? String, "elements.intent_confirmation_challenge.success")
        XCTAssertNil(payload?["captcha_vendor_name"])
        XCTAssertEqual(payload?["duration"] as? Double, 1500.0)
    }

    func testChallengeErrorAnalyticsIncludesCaptchaVendorName() {
        let analyticsClient = STPAnalyticsClient()
        analyticsClient.logIntentConfirmationChallengeError(error: ChallengeError.unknownError, duration: 1.5, captchaVendorName: "arkose")

        let payload = analyticsClient._testLogHistory.last
        XCTAssertEqual(payload?["event"] as? String, "elements.intent_confirmation_challenge.error")
        XCTAssertEqual(payload?["captcha_vendor_name"] as? String, "arkose")
        XCTAssertEqual(payload?["duration"] as? Double, 1500.0)
    }

    func testChallengeErrorAnalyticsExcludesCaptchaVendorNameWhenNil() {
        let analyticsClient = STPAnalyticsClient()
        analyticsClient.logIntentConfirmationChallengeError(error: ChallengeError.unknownError, duration: 1.5, captchaVendorName: nil)

        let payload = analyticsClient._testLogHistory.last
        XCTAssertEqual(payload?["event"] as? String, "elements.intent_confirmation_challenge.error")
        XCTAssertNil(payload?["captcha_vendor_name"])
        XCTAssertEqual(payload?["duration"] as? Double, 1500.0)
    }

    func testChallengeCanceledAnalyticsIncludesCaptchaVendorName() {
        let analyticsClient = STPAnalyticsClient()
        analyticsClient.logIntentConfirmationChallengeCanceled(duration: 1.5, captchaVendorName: "arkose")

        let payload = analyticsClient._testLogHistory.last
        XCTAssertEqual(payload?["event"] as? String, "elements.intent_confirmation_challenge.cancel")
        XCTAssertEqual(payload?["captcha_vendor_name"] as? String, "arkose")
        XCTAssertEqual(payload?["duration"] as? Double, 1500.0)
    }

    func testChallengeCanceledAnalyticsExcludesCaptchaVendorNameWhenNil() {
        let analyticsClient = STPAnalyticsClient()
        analyticsClient.logIntentConfirmationChallengeCanceled(duration: 1.5, captchaVendorName: nil)

        let payload = analyticsClient._testLogHistory.last
        XCTAssertEqual(payload?["event"] as? String, "elements.intent_confirmation_challenge.cancel")
        XCTAssertNil(payload?["captcha_vendor_name"])
        XCTAssertEqual(payload?["duration"] as? Double, 1500.0)
    }
}
