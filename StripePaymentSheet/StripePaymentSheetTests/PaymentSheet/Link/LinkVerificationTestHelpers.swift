//
//  LinkVerificationTestHelpers.swift
//  StripePaymentSheetTests
//

import OHHTTPStubs
import OHHTTPStubsSwift
@testable import StripePaymentSheet

enum LinkVerificationTestHelpers {
    static func makeStartVerificationRateLimitResponse() -> HTTPStubsResponse {
        let response: [String: Any] = [
            "error": [
                "message": LinkUtils.ConsumerErrorCode.consumerVerificationMaxAttemptsExceeded.localizedDescription,
                "code": LinkUtils.ConsumerErrorCode.consumerVerificationMaxAttemptsExceeded.rawValue,
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
