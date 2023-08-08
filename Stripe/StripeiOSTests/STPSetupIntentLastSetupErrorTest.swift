//  Converted to Swift 5.8.1 by Swiftify v5.8.28463 - https://swiftify.com/
//
//  STPSetupIntentLastSetupErrorTest.m
//  StripeiOS Tests
//
//  Created by Yuki Tokuhiro on 8/9/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

@testable import StripePayments

class STPSetupIntentLastSetupErrorTest: XCTestCase {
    func testTypeFromString() {
        XCTAssertEqual(STPSetupIntentLastSetupError.type(from: "api_connection_error"), STPSetupIntentLastSetupErrorType.apiConnection)
        XCTAssertEqual(STPSetupIntentLastSetupError.type(from: "API_CONNECTION_ERROR"), STPSetupIntentLastSetupErrorType.apiConnection)
        XCTAssertEqual(STPSetupIntentLastSetupError.type(from: "api_error"), STPSetupIntentLastSetupErrorType.API)
        XCTAssertEqual(STPSetupIntentLastSetupError.type(from: "API_ERROR"), STPSetupIntentLastSetupErrorType.API)
        XCTAssertEqual(STPSetupIntentLastSetupError.type(from: "authentication_error"), STPSetupIntentLastSetupErrorType.authentication)
        XCTAssertEqual(STPSetupIntentLastSetupError.type(from: "AUTHENTICATION_ERROR"), STPSetupIntentLastSetupErrorType.authentication)
        XCTAssertEqual(STPSetupIntentLastSetupError.type(from: "card_error"), STPSetupIntentLastSetupErrorType.card)
        XCTAssertEqual(STPSetupIntentLastSetupError.type(from: "CARD_ERROR"), STPSetupIntentLastSetupErrorType.card)
        XCTAssertEqual(STPSetupIntentLastSetupError.type(from: "idempotency_error"), STPSetupIntentLastSetupErrorType.idempotency)
        XCTAssertEqual(STPSetupIntentLastSetupError.type(from: "IDEMPOTENCY_ERROR"), STPSetupIntentLastSetupErrorType.idempotency)
        XCTAssertEqual(STPSetupIntentLastSetupError.type(from: "invalid_request_error"), STPSetupIntentLastSetupErrorType.invalidRequest)
        XCTAssertEqual(STPSetupIntentLastSetupError.type(from: "INVALID_REQUEST_ERROR"), STPSetupIntentLastSetupErrorType.invalidRequest)
        XCTAssertEqual(STPSetupIntentLastSetupError.type(from: "rate_limit_error"), STPSetupIntentLastSetupErrorType.rateLimit)
        XCTAssertEqual(STPSetupIntentLastSetupError.type(from: "RATE_LIMIT_ERROR"), STPSetupIntentLastSetupErrorType.rateLimit)
    }
    // MARK: - STPAPIResponseDecodable Tests

    // STPSetupIntentLastError is a sub-object of STPSetupIntent, see STPSetupIntentTest
}
