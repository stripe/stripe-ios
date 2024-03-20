//
//  AnalyticLoggableErrorTest.swift
//  StripeCoreTests
//
//  Created by Yuki Tokuhiro on 3/20/24.
//
//

import Foundation
import XCTest
@testable@_spi(STP) import StripeCore

class AnalyticLoggableErrorTest: XCTestCase {
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
