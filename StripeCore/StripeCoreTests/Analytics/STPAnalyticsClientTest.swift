//
//  STPAnalyticsTest.swift
//  StripeCoreTests
//
//  Created by Yuki Tokuhiro on 12/15/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import Foundation
import XCTest

@testable @_spi(STP) import StripeCore

class STPAnalyticsClientTest: XCTestCase {

    func testShouldCollectAnalytics_alwaysFalseInTest() {
        XCTAssertFalse(STPAnalyticsClient.shouldCollectAnalytics())
    }
    
    func testShouldRedactLiveKeyFromLog() {
        let analyticsClient = STPAnalyticsClient()
        
        let payload = analyticsClient.commonPayload(STPAPIClient(publishableKey: "sk_live_foo"))
        
        XCTAssertEqual("[REDACTED_LIVE_KEY]", payload["publishable_key"] as? String)
    }
    
    func testShouldNotRedactLiveKeyFromLog() {
        let analyticsClient = STPAnalyticsClient()
        
        let payload = analyticsClient.commonPayload(STPAPIClient(publishableKey: "pk_foo"))
        
        XCTAssertEqual("pk_foo", payload["publishable_key"] as? String)
    }

}
