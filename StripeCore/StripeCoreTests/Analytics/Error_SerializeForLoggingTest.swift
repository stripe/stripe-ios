//
//  Error_SerializeForLoggingTest.swift
//  StripeCoreTests
//
//  Created by Nick Porter on 9/8/21.
//

import Foundation
import XCTest

@testable @_spi(STP) import StripeCore

class Error_SerializeForLoggingTest: XCTestCase {

    struct CustomLoggableError: Error, AnalyticLoggableError {
        func analyticLoggableSerializeForLogging() -> [String : Any] {
            return [
                "foo": "value"
            ]
        }
    }

    enum StringError: String, AnalyticLoggableStringError {
        case foo
    }

    func testNSErrorSerializedForLogging() throws {
        let error = NSError(domain: "test-domain", code: 1, userInfo: ["description": "test-description"])
        
        let serializedError = error.serializeForLogging()
        
        XCTAssertEqual(serializedError.count, 2)
        XCTAssertEqual("test-domain", serializedError["domain"] as? String)
        XCTAssertEqual(serializedError["code"] as? Int, 1)
    }

    /// Tests that casting an the error to `Error` still uses custom
    /// serialization as opposed to the NSError default behavior
    func testAnalyticLoggableSerializedForLogging() {
        let error: Error = CustomLoggableError()

        let serializedError = error.serializeForLogging()

        XCTAssertEqual(serializedError.count, 1)
        XCTAssertEqual(serializedError["foo"] as? String, "value")
    }

    func testStringErrorSerializeForLogging() {
        let error: Error = StringError.foo

        let serializedError = error.serializeForLogging()

        print(serializedError)

        XCTAssertEqual(serializedError.count, 2)
        XCTAssertEqual(serializedError["type"] as? String, "foo")
        XCTAssertEqual(serializedError["domain"] as? String, "StripeCoreTests.Error_SerializeForLoggingTest.StringError")
    }
}
