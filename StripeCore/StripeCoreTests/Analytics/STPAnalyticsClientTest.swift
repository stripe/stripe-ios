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

    // MARK: - Test serialization

    func testSerializeError() {
        let userInfo = [
            "key1": "value1",
            "key2": "value2",
        ]
        let error = NSError(domain: "test_domain", code: 42, userInfo: userInfo)
        let serializedError = STPAnalyticsClient.serializeError(error)
        XCTAssertEqual(serializedError.count, 3)
        XCTAssertEqual(serializedError["domain"] as? String, "test_domain")
        XCTAssertEqual(serializedError["code"] as? Int, 42)
        XCTAssertEqual(serializedError["user_info"] as? [String: String], userInfo)
    }
}
