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
}
