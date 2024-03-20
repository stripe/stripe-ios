//
//  Error_SerializeForLoggingTest.swift
//  StripeCoreTests
//
//  Created by Nick Porter on 9/8/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation
import XCTest

@testable@_spi(STP) import StripeCore

class Error_SerializeForLoggingTest: XCTestCase {

    struct CustomLoggableError: Error, AnalyticLoggableErrorV2 {
        func analyticLoggableSerializeForLogging() -> [String: Any] {
            return [
                "foo": "value",
            ]
        }
    }

    enum StringError: String, AnalyticLoggableStringErrorV2 {
        case foo
    }

    func testNSErrorSerializedForLogging() throws {
        let error = NSError(
            domain: "test-domain",
            code: 1,
            userInfo: ["description": "test-description"]
        )

        let serializedError = error.serializeForV2Logging()

        XCTAssertEqual(serializedError.count, 2)
        XCTAssertEqual("test-domain", serializedError["domain"] as? String)
        XCTAssertEqual(serializedError["code"] as? Int, 1)
    }

    /// Tests that casting an the error to `Error` still uses custom
    /// serialization as opposed to the NSError default behavior.
    func testAnalyticLoggableSerializedForLogging() {
        let error: Error = CustomLoggableError()

        let serializedError = error.serializeForV2Logging()

        XCTAssertEqual(serializedError.count, 1)
        XCTAssertEqual(serializedError["foo"] as? String, "value")
    }

    func testStringErrorSerializeForLogging() {
        let error: Error = StringError.foo

        let serializedError = error.serializeForV2Logging()

        print(serializedError)

        XCTAssertEqual(serializedError.count, 2)
        XCTAssertEqual(serializedError["type"] as? String, "foo")
        XCTAssertEqual(
            serializedError["domain"] as? String,
            "StripeCoreTests.Error_SerializeForLoggingTest.StringError"
        )
    }

    enum BasicSwiftError: Error {
        case foo
        case bar(pii: String)
    }

    enum BasicSwiftErrorWithDebugDescription: Error, CustomDebugStringConvertible {
        case someErrorCase
        case someOtherCase(pii: String)

        var debugDescription: String {
            switch self {
            case .someErrorCase:
                "Some error occurred."
            case .someOtherCase(let pii):
                "Some other error occured with this PII: \(pii)"
            }
        }
    }

    func testSerializeForV1Logging() {
        // Stripe API Error
        let stripeAPIError = NSError.stp_error(fromStripeResponse: [
            "error": [
                "type": "card_error",
                "message": "Your card number is incorrect.",
                "code": "incorrect_number",
            ],
        ])!
        XCTAssertEqual(
            stripeAPIError.serializeForV1Analytics() as? [String: String],
            [
                "error_type": "card_error",
                "error_code": "incorrect_number",
            ]
        )

        // Decoding Error from an iOS library
        let decodingError = DecodingError.keyNotFound(STPCodingKey(intValue: 0)!, .init(codingPath: [], debugDescription: "PII"))
        XCTAssertEqual(
            decodingError.serializeForV1Analytics() as? [String: String],
            [
                "error_type": "Swift.DecodingError",
                "error_code": "keyNotFound",
            ]
        )

        // Swift Error
        let swiftError = BasicSwiftError.foo
        XCTAssertEqual(
            swiftError.serializeForV1Analytics() as? [String: String],
            [
                "error_type": "StripeCoreTests.Error_SerializeForLoggingTest.BasicSwiftError",
                "error_code": "foo",
            ]
        )

        // Swift Error with associated value - shouldn't include associated value
        let swiftErrorWithPIIInAssociatedValue = BasicSwiftError.bar(pii: "pii")
        XCTAssertEqual(
            swiftErrorWithPIIInAssociatedValue.serializeForV1Analytics() as? [String: String],
            [
                "error_type": "StripeCoreTests.Error_SerializeForLoggingTest.BasicSwiftError",
                "error_code": "bar",
            ]
        )

        // Swift Error with debug description - ok to use debug description for case w/o associated value
        let swiftErrorWithDebugDescription = BasicSwiftErrorWithDebugDescription.someErrorCase
        XCTAssertEqual(
            swiftErrorWithDebugDescription.serializeForV1Analytics() as? [String: String],
            [
                "error_type": "StripeCoreTests.Error_SerializeForLoggingTest.BasicSwiftErrorWithDebugDescription",
                "error_code": "Some error occurred.",
            ]
        )

        // Swift Error with associated value and debug description - should use case name
        let swiftErrorWithPIIInAssociatedValueAndDebugDescription = BasicSwiftErrorWithDebugDescription.someOtherCase(pii: "pii")
        XCTAssertEqual(
            swiftErrorWithPIIInAssociatedValueAndDebugDescription.serializeForV1Analytics() as? [String: String],
            [
                "error_type": "StripeCoreTests.Error_SerializeForLoggingTest.BasicSwiftErrorWithDebugDescription",
                "error_code": "someOtherCase",
            ]
        )

        // NSError
        let nsURLError = NSError(
            domain: NSURLErrorDomain,
            code: NSURLErrorNotConnectedToInternet,
            userInfo: nil
        )
        XCTAssertEqual(
            nsURLError.serializeForV1Analytics() as? [String: String],
            [
                "error_type": "NSURLErrorDomain",
                "error_code": "-1009",
            ]
        )
    }
}
