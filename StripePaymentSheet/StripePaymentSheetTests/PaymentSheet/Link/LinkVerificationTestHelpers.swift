//
//  LinkVerificationTestHelpers.swift
//  StripePaymentSheetTests
//

import OHHTTPStubs
import OHHTTPStubsSwift

enum LinkVerificationTestHelpers {
    static func makeStartVerificationRateLimitResponse() -> HTTPStubsResponse {
        let response: [String: Any] = [
            "error": [
                "message": "Too many attempts. Please try again in a few minutes.",
                "code": "consumer_verification_max_attempts_exceeded",
                "type": "invalid_request_error",
            ],
        ]
        return HTTPStubsResponse(
            jsonObject: response,
            statusCode: 429,
            headers: ["Content-Type": "application/json"]
        )
    }
}
