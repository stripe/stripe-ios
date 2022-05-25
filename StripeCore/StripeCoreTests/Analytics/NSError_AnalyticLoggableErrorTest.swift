//
//  NSError_AnalyticLoggableErrorTest.swift
//  StripeCoreTests
//
//  Created by Nick Porter on 9/8/21.
//

import Foundation
import XCTest

@testable @_spi(STP) import StripeCore

class NSError_AnalyticLoggableErrorTest: XCTestCase {

    func testNSErrorSerializedForLogging() throws {
        let error = NSError(domain: "test-domain", code: 1, userInfo: ["description": "test-description"])
        
        let serializedError = error.serializeForLogging()
        
        XCTAssertEqual(2, serializedError.count)
        XCTAssertEqual("test-domain", serializedError["domain"] as? String)
        XCTAssertEqual(1, serializedError["code"] as? Int)
    }
}
