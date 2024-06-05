//
//  STPAnalyticsClientTest.swift
//  StripeCoreTests
//
//  Created by Yuki Tokuhiro on 12/15/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import Foundation
import XCTest

@testable@_spi(STP) import StripeCore

class STPAnalyticsClientTest: XCTestCase {

    func testIsUnitOrUITest_alwaysTrueInTest() {
        XCTAssertTrue(STPAnalyticsClient.isUnitOrUITest)
    }

    func testShouldRedactLiveKeyFromLog() {
        let analyticsClient = STPAnalyticsClient()

        let payload = analyticsClient.commonPayload(STPAPIClient(publishableKey: "sk_live_foo"))

        XCTAssertEqual("[REDACTED_LIVE_KEY]", payload["publishable_key"] as? String)
    }

    func testShouldRedactUserKeyFromLog() {
        let analyticsClient = STPAnalyticsClient()

        let payload = analyticsClient.commonPayload(STPAPIClient(publishableKey: "uk_live_foo"))

        XCTAssertEqual("[REDACTED_LIVE_KEY]", payload["publishable_key"] as? String)
    }

    func testShouldNotRedactLiveKeyFromLog() {
        let analyticsClient = STPAnalyticsClient()

        let payload = analyticsClient.commonPayload(STPAPIClient(publishableKey: "pk_foo"))

        XCTAssertEqual("pk_foo", payload["publishable_key"] as? String)
    }

    func testLogShouldRespectAPIClient() {
        STPAPIClient.shared.publishableKey = "pk_shared"
        let apiClient = STPAPIClient(publishableKey: "pk_not_shared")
        let analyticsClient = STPAnalyticsClient()
        // ...logging an arbitrary analytic and passing apiClient...
        analyticsClient.log(analytic: GenericAnalytic.init(event: .addressShow, params: [:]), apiClient: apiClient)
        // ...should use the passed in apiClient publishable key and not the shared apiClient
        let payload = analyticsClient._testLogHistory.first!
        XCTAssertEqual("pk_not_shared", payload["publishable_key"] as? String)
    }
}
