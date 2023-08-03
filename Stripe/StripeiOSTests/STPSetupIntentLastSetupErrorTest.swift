//  Converted to Swift 5.8.1 by Swiftify v5.8.28463 - https://swiftify.com/
import Foundation
import XCTest

@testable@_spi(STP) import Stripe
@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePayments
@testable@_spi(STP) import StripePaymentSheet
@testable@_spi(STP) import StripePaymentsUI
//
//  STPSetupIntentLastSetupErrorTest.swift
//  StripeiOS Tests
//
//  Created by Yuki Tokuhiro on 8/9/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

import Stripe

extension STPSetupIntentLastSetupError {
    class func type(from string: String?) -> STPSetupIntentLastSetupErrorType {
    }
}

class STPSetupIntentLastSetupErrorTest: XCTestCase {
    func testTypeFromString() {
        XCTAssertEqual(Int(STPSetupIntentLastSetupError.type(from: "api_connection_error")), Int(STPSetupIntentLastSetupErrorTypeAPIConnection))
        XCTAssertEqual(Int(STPSetupIntentLastSetupError.type(from: "API_CONNECTION_ERROR")), Int(STPSetupIntentLastSetupErrorTypeAPIConnection))
        XCTAssertEqual(Int(STPSetupIntentLastSetupError.type(from: "api_error")), Int(STPSetupIntentLastSetupErrorTypeAPI))
        XCTAssertEqual(Int(STPSetupIntentLastSetupError.type(from: "API_ERROR")), Int(STPSetupIntentLastSetupErrorTypeAPI))
        XCTAssertEqual(Int(STPSetupIntentLastSetupError.type(from: "authentication_error")), Int(STPSetupIntentLastSetupErrorTypeAuthentication))
        XCTAssertEqual(Int(STPSetupIntentLastSetupError.type(from: "AUTHENTICATION_ERROR")), Int(STPSetupIntentLastSetupErrorTypeAuthentication))
        XCTAssertEqual(Int(STPSetupIntentLastSetupError.type(from: "card_error")), Int(STPSetupIntentLastSetupErrorTypeCard))
        XCTAssertEqual(Int(STPSetupIntentLastSetupError.type(from: "CARD_ERROR")), Int(STPSetupIntentLastSetupErrorTypeCard))
        XCTAssertEqual(Int(STPSetupIntentLastSetupError.type(from: "idempotency_error")), Int(STPSetupIntentLastSetupErrorTypeIdempotency))
        XCTAssertEqual(Int(STPSetupIntentLastSetupError.type(from: "IDEMPOTENCY_ERROR")), Int(STPSetupIntentLastSetupErrorTypeIdempotency))
        XCTAssertEqual(Int(STPSetupIntentLastSetupError.type(from: "invalid_request_error")), Int(STPSetupIntentLastSetupErrorTypeInvalidRequest))
        XCTAssertEqual(Int(STPSetupIntentLastSetupError.type(from: "INVALID_REQUEST_ERROR")), Int(STPSetupIntentLastSetupErrorTypeInvalidRequest))
        XCTAssertEqual(Int(STPSetupIntentLastSetupError.type(from: "rate_limit_error")), Int(STPSetupIntentLastSetupErrorTypeRateLimit))
        XCTAssertEqual(Int(STPSetupIntentLastSetupError.type(from: "RATE_LIMIT_ERROR")), Int(STPSetupIntentLastSetupErrorTypeRateLimit))
    }
    // MARK: - STPAPIResponseDecodable Tests

    // STPSetupIntentLastError is a sub-object of STPSetupIntent, see STPSetupIntentTest
}
