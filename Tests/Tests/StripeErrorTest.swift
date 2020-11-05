//
//  StripeErrorTest.swift
//  Stripe
//
//  Created by Ben Guo on 4/14/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//
@testable import Stripe

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
      error.userInfo[NSLocalizedDescriptionKey] as! String, NSError.stp_unexpectedErrorMessage())
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
      error.userInfo[NSLocalizedDescriptionKey] as! String?, NSError.stp_unexpectedErrorMessage())
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
      error.userInfo[NSLocalizedDescriptionKey] as? String, response["error"]!["message"])
    XCTAssertEqual(
      error.userInfo[STPError.errorMessageKey] as? String, response["error"]!["message"])
    XCTAssertEqual(
      error.userInfo[STPError.stripeErrorTypeKey] as? String, response["error"]!["type"])
    XCTAssertEqual(error.userInfo[STPError.errorParameterKey] as! String, "card[expYear]")
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
    XCTAssertEqual(error.userInfo[STPError.cardErrorCodeKey] as! String, STPError.incorrectNumber)
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
    XCTAssertEqual(error.userInfo[STPError.cardErrorCodeKey] as! String, STPError.incorrectNumber)
    XCTAssertEqual(
      error.userInfo[STPError.stripeErrorTypeKey] as? String, response["error"]!["type"])
    XCTAssertEqual(
      error.userInfo[STPError.stripeErrorCodeKey] as? String, response["error"]!["code"])
    XCTAssertEqual(
      error.userInfo[STPError.errorMessageKey] as? String, response["error"]!["message"])
  }
}
