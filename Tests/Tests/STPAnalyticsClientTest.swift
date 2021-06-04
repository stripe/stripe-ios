//
//  STPAnalyticsTest.swift
//  StripeiOS Tests
//
//  Created by Yuki Tokuhiro on 12/15/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import Foundation
import XCTest

@testable import Stripe

class STPAnalyticsClientTestSwift: XCTestCase {

    // TODO(mludowise|MOBILESDK-292): Migrate objc tests to swift
    
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
