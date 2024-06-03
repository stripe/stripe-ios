//
//  AnalyticLoggableErrorTest.swift
//  StripeCoreTests
//
//  Created by Yuki Tokuhiro on 3/20/24.
//
//

import Foundation
@testable@_spi(STP) import StripeCore
import XCTest

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
        let stripeAPIErrorJSON = [
            "error": [
                "type": "card_error",
                "message": "Your card number is incorrect.",
                "code": "incorrect_number",
            ],
        ]
        let stripeAPIErrorHTTPResponse = HTTPURLResponse(url: URL(string: "https://api.stripe.com/v1/some_endpoint")!, statusCode: 402, httpVersion: nil, headerFields: ["request-id": "req_123"])
        let stripeAPIError = NSError.stp_error(fromStripeResponse: stripeAPIErrorJSON, httpResponse: stripeAPIErrorHTTPResponse)!
        XCTAssertEqual(
            stripeAPIError.serializeForV1Analytics() as? [String: String],
            [
                "error_type": "card_error",
                "error_code": "incorrect_number",
                "request_id": "req_123",
            ]
        )

        // StripeCore.StripeError.stripeAPIError - same as above, but different type
        let stripeAPIErrorJSONData = try! JSONSerialization.data(
            withJSONObject: stripeAPIErrorJSON,
            options: [.prettyPrinted]
        )
        let stripeCoreStripeError = STPAPIClient.decodeStripeErrorResponse(data: stripeAPIErrorJSONData, response: stripeAPIErrorHTTPResponse)!
        XCTAssertEqual(
            stripeCoreStripeError.serializeForV1Analytics() as? [String: String],
            [
                "error_type": "card_error",
                "error_code": "incorrect_number",
                "request_id": "req_123",
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
                "error_type": "StripeCoreTests.AnalyticLoggableErrorTest.BasicSwiftError",
                "error_code": "foo",
            ]
        )

        // Swift Error with associated value - shouldn't include associated value
        let swiftErrorWithPIIInAssociatedValue = BasicSwiftError.bar(pii: "pii")
        XCTAssertEqual(
            swiftErrorWithPIIInAssociatedValue.serializeForV1Analytics() as? [String: String],
            [
                "error_type": "StripeCoreTests.AnalyticLoggableErrorTest.BasicSwiftError",
                "error_code": "bar",
            ]
        )

        // Swift Error with debug description - ok to use debug description for case w/o associated value
        let swiftErrorWithDebugDescription = BasicSwiftErrorWithDebugDescription.someErrorCase
        XCTAssertEqual(
            swiftErrorWithDebugDescription.serializeForV1Analytics() as? [String: String],
            [
                "error_type": "StripeCoreTests.AnalyticLoggableErrorTest.BasicSwiftErrorWithDebugDescription",
                "error_code": "Some error occurred.",
            ]
        )

        // Swift Error with associated value and debug description - should use case name
        let swiftErrorWithPIIInAssociatedValueAndDebugDescription = BasicSwiftErrorWithDebugDescription.someOtherCase(pii: "pii")
        XCTAssertEqual(
            swiftErrorWithPIIInAssociatedValueAndDebugDescription.serializeForV1Analytics() as? [String: String],
            [
                "error_type": "StripeCoreTests.AnalyticLoggableErrorTest.BasicSwiftErrorWithDebugDescription",
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

    func testAnalyticLoggableError() {
        // Implementing `AnalyticLoggableError`...
        enum MyError: Error, AnalyticLoggableError, CustomDebugStringConvertible {
            case invalidClientSecret(clientSecret: String)
            var debugDescription: String {
                switch self {
                case .invalidClientSecret(clientSecret: let clientSecret):
                    return "Invalid client secret provided starting with \(clientSecret.prefix(5))"
                }
            }

            // ...and overriding everything...
            var analyticsErrorType: String {
                return "overriden error type"
            }
            var analyticsErrorCode: String {
                return "overridden error code"
            }

            // ...and using additionalNonPIIErrorDetails...
            var additionalNonPIIErrorDetails: [String: Any] {
                switch self {
                case .invalidClientSecret(clientSecret: let clientSecret):
                    return [
                        "client_secret_snippet": String(clientSecret.prefix(5)),
                    ]
                }
            }
        }

        // ...should use all the custom values...
        let analyticsClient = STPAnalyticsClient()
        analyticsClient.log(analytic: ErrorAnalytic(event: ._3DS2ChallengeFlowErrored, error: MyError.invalidClientSecret(clientSecret: "cs_12345")))

        let log = analyticsClient._testLogHistory.first!
        XCTAssertEqual(log["error_type"] as? String, "overriden error type")
        XCTAssertEqual(log["error_code"] as? String, "overridden error code")
        let errorDetails = log["error_details"] as? [String: Any]
        XCTAssertEqual(errorDetails?["client_secret_snippet"] as? String, "cs_12")
        XCTAssertEqual(errorDetails?.keys.count, 1)
    }
}
