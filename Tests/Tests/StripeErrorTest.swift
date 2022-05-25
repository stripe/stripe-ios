//
//  StripeErrorTest.swift
//  Stripe
//
//  Created by Ben Guo on 4/14/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

import XCTest
import Foundation
@testable import Stripe
@_spi(STP) @testable import StripeCore

class StripeErrorTest: XCTestCase {
    func testEmptyResponse() {
        let response: [AnyHashable: Any] = [:]
        let error = NSError.stp_error(fromStripeResponse: response)
        XCTAssertNil(error)
    }

    func testResponseWithUnknownTypeAndNoMessage() {
        let response = [
            "error": [
                "type": "foo",
                "code": "error_code",
            ]
        ]
        let error = NSError.stp_error(fromStripeResponse: response)!
        XCTAssertEqual(error.domain, STPError.stripeDomain)
        XCTAssertEqual(error.code, STPErrorCode.apiError.rawValue)
        XCTAssertEqual(
            error.userInfo[NSLocalizedDescriptionKey] as! String,
            NSError.stp_unexpectedErrorMessage())
        XCTAssertEqual(
            error.userInfo[STPError.stripeErrorTypeKey] as! String, response["error"]!["type"]!)
        XCTAssertEqual(
            error.userInfo[STPError.stripeErrorCodeKey] as! String, response["error"]!["code"]!)
        XCTAssertTrue(
            (error.userInfo[STPError.errorMessageKey]! as! String).hasPrefix(
                "Could not interpret the error response"))
    }

    func testAPIError() {
        let response = [
            "error": [
                "type": "api_error",
                "message": "some message",
            ]
        ]
        let error = NSError.stp_error(fromStripeResponse: response)!
        XCTAssertEqual(error.domain, STPError.stripeDomain)
        XCTAssertEqual(error.code, STPErrorCode.apiError.rawValue)
        XCTAssertEqual(
            error.userInfo[NSLocalizedDescriptionKey] as! String?,
            NSError.stp_unexpectedErrorMessage())
        XCTAssertEqual(
            error.userInfo[STPError.errorMessageKey] as! String?, response["error"]!["message"])
        XCTAssertEqual(
            error.userInfo[STPError.stripeErrorTypeKey] as! String?, response["error"]!["type"])
    }

    func testInvalidRequestErrorMissingParameter() {
        let response = [
            "error": [
                "type": "invalid_request_error",
                "message": "The payment method `card` requires the parameter: card[exp_year].",
                "param": "card[exp_year]",
            ]
        ]
        let error = NSError.stp_error(fromStripeResponse: response)!
        XCTAssertEqual(error.domain, STPError.stripeDomain)
        XCTAssertEqual(error.code, STPErrorCode.invalidRequestError.rawValue)
        XCTAssertEqual(
            error.userInfo[NSLocalizedDescriptionKey] as? String,
            NSError.stp_unexpectedErrorMessage())
        XCTAssertEqual(
            error.userInfo[STPError.errorMessageKey] as? String, response["error"]!["message"])
        XCTAssertEqual(
            error.userInfo[STPError.stripeErrorTypeKey] as? String, response["error"]!["type"])
        XCTAssertEqual(error.userInfo[STPError.errorParameterKey] as! String, "card[expYear]")
    }

    func testAuthenticationError() {
        // Given an `invalid_request_error` response
        let response = [
            "error": [
                "type": "invalid_request_error",
                "message": "Invalid API Key provided: pk_test_***************************00",
            ]
        ]

        // with a `401` HTTP status code
        let httpResponse = HTTPURLResponse(
            url: URL(string: "https://api.stripe.com/v1/payment_intents")!,
            statusCode: 401,
            httpVersion: "1.1",
            headerFields: nil
        )

        let error = NSError.stp_error(fromStripeResponse: response, httpResponse: httpResponse)!

        XCTAssertEqual(error.domain, STPError.stripeDomain)
        XCTAssertEqual(error.code, STPErrorCode.authenticationError.rawValue,
            "`error.code` should be equals to `STPErrorCode.authenticationError`"
        )
    }

    func testAuthenticationErrorDueToExpiredKey() {
        // Given an `invalid_request_error` response due to an expired key
        let response = [
            "error": [
                "code": "api_key_expired",
                "type": "invalid_request_error",
                "message": "Expired API Key provided: pk_test_***************************00"
            ]
        ]

        // with a `401` HTTP status code
        let httpResponse = HTTPURLResponse(
            url: URL(string: "https://api.stripe.com/v1/payment_intents")!,
            statusCode: 401,
            httpVersion: "1.1",
            headerFields: nil
        )

        let error = NSError.stp_error(fromStripeResponse: response, httpResponse: httpResponse)!

        XCTAssertEqual(error.domain, STPError.stripeDomain)
        XCTAssertEqual(error.code, STPErrorCode.authenticationError.rawValue,
            "`error.code` should be equals to `STPErrorCode.authenticationError`"
        )
    }

    func testInvalidRequestErrorIncorrectNumber() {
        let response = [
            "error": [
                "type": "invalid_request_error",
                "message": "Your card number is incorrect.",
                "code": "incorrect_number",
            ]
        ]
        let error = NSError.stp_error(fromStripeResponse: response)!
        XCTAssertEqual(error.domain, STPError.stripeDomain)
        XCTAssertEqual(error.code, STPErrorCode.invalidRequestError.rawValue)
        XCTAssertEqual(
            error.userInfo[NSLocalizedDescriptionKey] as! String,
            NSError.stp_cardErrorInvalidNumberUserMessage())
        XCTAssertEqual(
            error.userInfo[STPError.cardErrorCodeKey] as! String, STPError.incorrectNumber)
        XCTAssertEqual(
            error.userInfo[STPError.stripeErrorTypeKey] as? String, response["error"]!["type"])
        XCTAssertEqual(
            error.userInfo[STPError.stripeErrorCodeKey] as? String, response["error"]!["code"])
        XCTAssertEqual(
            error.userInfo[STPError.errorMessageKey] as? String, response["error"]!["message"])
    }

    func testCardErrorIncorrectNumber() {
        let response = [
            "error": [
                "type": "card_error",
                "message": "Your card number is incorrect.",
                "code": "incorrect_number",
            ]
        ]
        let error = NSError.stp_error(fromStripeResponse: response)!
        XCTAssertEqual(error.domain, STPError.stripeDomain)
        XCTAssertEqual(error.code, STPErrorCode.cardError.rawValue)
        XCTAssertEqual(
            error.userInfo[NSLocalizedDescriptionKey] as! String,
            NSError.stp_cardErrorInvalidNumberUserMessage())
        XCTAssertEqual(
            error.userInfo[STPError.cardErrorCodeKey] as! String, STPError.incorrectNumber)
        XCTAssertEqual(
            error.userInfo[STPError.stripeErrorTypeKey] as? String, response["error"]!["type"])
        XCTAssertEqual(
            error.userInfo[STPError.stripeErrorCodeKey] as? String, response["error"]!["code"])
        XCTAssertEqual(
            error.userInfo[STPError.errorMessageKey] as? String, response["error"]!["message"])
    }

    func testCardDeclinedError() {
        let response = [
            "error": [
                "type": "card_error",
                "message": "Your card has insufficient funds.",
                "code": "card_declined",
                "decline_code": "insufficient_funds",
            ]
        ]
        guard let error = NSError.stp_error(fromStripeResponse: response) else {
            XCTFail()
            return
        }
        XCTAssertEqual(error.domain, STPError.stripeDomain)
        XCTAssertEqual(error.code, STPErrorCode.cardError.rawValue)
        XCTAssertEqual(error.userInfo[STPError.cardErrorCodeKey] as? String, STPCardErrorCode.cardDeclined.rawValue)
        XCTAssertEqual(error.userInfo[NSLocalizedDescriptionKey] as? String, NSError.stp_cardErrorDeclinedUserMessage())
        XCTAssertEqual(error.userInfo[STPError.stripeDeclineCodeKey] as? String, "insufficient_funds")
    }
}
