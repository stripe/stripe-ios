//
//  STPPaymentIntentLastPaymentErrorTest.swift
//  StripeiOS Tests
//
//  Created by Cameron Sabol on 9/29/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import XCTest

@testable import Stripe

class STPPaymentIntentLastPaymentErrorTest: XCTestCase {

  func testErrorType() {
    XCTAssertEqual(
      STPPaymentIntentLastPaymentErrorType(string: "api_connection_error"), .apiConnection)
    XCTAssertEqual(
      STPPaymentIntentLastPaymentErrorType(string: "API_CONNECTION_ERROR"), .apiConnection)
    XCTAssertEqual(STPPaymentIntentLastPaymentErrorType(string: "api_error"), .api)
    XCTAssertEqual(STPPaymentIntentLastPaymentErrorType(string: "API_ERROR"), .api)
    XCTAssertEqual(
      STPPaymentIntentLastPaymentErrorType(string: "authentication_error"), .authentication)
    XCTAssertEqual(
      STPPaymentIntentLastPaymentErrorType(string: "AUTHENTICATION_ERROR"), .authentication)
    XCTAssertEqual(STPPaymentIntentLastPaymentErrorType(string: "card_error"), .card)
    XCTAssertEqual(STPPaymentIntentLastPaymentErrorType(string: "CARD_ERROR"), .card)
    XCTAssertEqual(STPPaymentIntentLastPaymentErrorType(string: "idempotency_error"), .idempotency)
    XCTAssertEqual(STPPaymentIntentLastPaymentErrorType(string: "IDEMPOTENCY_ERROR"), .idempotency)
    XCTAssertEqual(
      STPPaymentIntentLastPaymentErrorType(string: "invalid_request_error"), .invalidRequest)
    XCTAssertEqual(
      STPPaymentIntentLastPaymentErrorType(string: "INVALID_REQUEST_ERROR"), .invalidRequest)
    XCTAssertEqual(STPPaymentIntentLastPaymentErrorType(string: "rate_limit_error"), .rateLimit)
    XCTAssertEqual(STPPaymentIntentLastPaymentErrorType(string: "RATE_LIMIT_ERROR"), .rateLimit)
  }

}
