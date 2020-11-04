//
//  APIRequestTest.swift
//  StripeiOS Tests
//
//  Created by Yuki Tokuhiro on 9/23/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import XCTest

@testable import Stripe

class AnyAPIResponse: NSObject, STPAPIResponseDecodable {
  override required init() {
    super.init()
  }

  static func decodedObject(fromAPIResponse response: [AnyHashable: Any]?) -> Self? {
    guard let response = response else {
      return nil
    }
    let a = Self()
    a.allResponseFields = response
    return a
  }

  var allResponseFields: [AnyHashable: Any] = [:]

}

class APIRequestTest: XCTestCase {
  let apiClient = STPAPIClient()
  override func setUp() {
    apiClient.apiURL = URL(string: "https://httpbin.org/")
  }

  func testPublishableKeyAuthorization() {
    let e = expectation(description: "Request completed")
    apiClient.publishableKey = "pk_foo"
    APIRequest<AnyAPIResponse>.getWith(apiClient, endpoint: "bearer", parameters: ["foo": "bar"]) {
      (obj, _, error) in
      guard let obj = obj,
        let token = obj.allResponseFields["token"] as? String
      else {
        XCTFail()
        XCTAssertNil(error)
        return
      }
      XCTAssertEqual(token, self.apiClient.publishableKey)
      e.fulfill()
    }
    waitForExpectations(timeout: 2)
  }

  func testStripeAccountAuthorization() {

  }

  func testGet() {
    let e = expectation(description: "Request completed")
    APIRequest<AnyAPIResponse>.getWith(apiClient, endpoint: "get", parameters: [:]) {
      (obj, response, error) in
      XCTAssertNil(error)
      XCTAssertEqual(response?.statusCode, 200)
      XCTAssertNotNil(obj)
      e.fulfill()
    }
    waitForExpectations(timeout: 2)
  }

  func testPost() {
    let parameters = ["foo": "bar"]
    let e = expectation(description: "Request completed")
    APIRequest<AnyAPIResponse>.post(with: apiClient, endpoint: "post", parameters: ["foo": "bar"]) {
      (obj, response, error) in
      XCTAssertNil(error)
      XCTAssertEqual(response?.statusCode, 200)
      guard let obj = obj,
        let form = obj.allResponseFields["form"] as? [String: String],
        let headers = obj.allResponseFields["headers"] as? [String: String]
      else {
        XCTFail()
        return
      }
      XCTAssertNotNil(headers["X-Stripe-User-Agent"])
      XCTAssertEqual(headers["Stripe-Version"], STPAPIClient.apiVersion)
      XCTAssertEqual(form, parameters)
      e.fulfill()
    }
    waitForExpectations(timeout: 2)
  }

  func testDelete() {
    let e = expectation(description: "Request completed")
    APIRequest<AnyAPIResponse>.delete(with: apiClient, endpoint: "delete", parameters: [:]) {
      (obj, response, error) in
      XCTAssertNil(error)
      XCTAssertEqual(response?.statusCode, 200)
      guard let obj = obj,
        let headers = obj.allResponseFields["headers"] as? [String: String]
      else {
        XCTFail()
        return
      }
      XCTAssertNotNil(headers["X-Stripe-User-Agent"])
      XCTAssertEqual(headers["Stripe-Version"], STPAPIClient.apiVersion)

      e.fulfill()
    }
    waitForExpectations(timeout: 2)
  }

  func testParseResponseWithConnectionError() {
    let expectation = self.expectation(description: "parseResponse")

    let httpURLResponse = HTTPURLResponse()
    let json: [AnyHashable: Any] = [:]
    let body = try? JSONSerialization.data(withJSONObject: json, options: [])
    let errorParameter = NSError(
      domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet, userInfo: nil)

    APIRequest<STPCard>.parseResponse(
      httpURLResponse,
      body: body,
      error: errorParameter
    ) { (object: STPCard?, response, error) in
      guard let error = error else {
        XCTFail()
        return
      }
      XCTAssertNil(object)
      XCTAssertEqual(response, httpURLResponse)
      XCTAssertEqual(error as NSError, errorParameter)
      expectation.fulfill()
    }

    waitForExpectations(timeout: 2.0, handler: nil)
  }

  func testParseResponseWithReturnedError() {
    let expectation = self.expectation(description: "parseResponse")

    let httpURLResponse = HTTPURLResponse()
    let json = [
      "error": [
        "type": "invalid_request_error",
        "message": "Your card number is incorrect.",
        "code": "incorrect_number",
      ]
    ]
    let body = try? JSONSerialization.data(withJSONObject: json, options: [])
    let errorParameter: NSError? = nil
    let expectedError = NSError.stp_error(fromStripeResponse: json)

    APIRequest<STPCard>.parseResponse(
      httpURLResponse,
      body: body,
      error: errorParameter
    ) { (object: STPCard?, response, error) in
      guard let error = error, let expectedError = expectedError else {
        XCTFail()
        return
      }
      XCTAssertNil(object)
      XCTAssertEqual(response, httpURLResponse)
      XCTAssertEqual(error as NSError, expectedError as NSError)
      expectation.fulfill()
    }

    waitForExpectations(timeout: 2.0, handler: nil)
  }

  func testParseResponseWithMissingError() {
    let expectation = self.expectation(description: "parseResponse")

    let httpURLResponse = HTTPURLResponse()
    let json: [AnyHashable: Any] = [:]
    let body = try? JSONSerialization.data(withJSONObject: json, options: [])
    let errorParameter: NSError? = nil
    let expectedError = NSError.stp_genericFailedToParseResponseError()

    APIRequest<STPCard>.parseResponse(
      httpURLResponse,
      body: body,
      error: errorParameter
    ) { (object: STPCard?, response, error) in
      guard let error = error else {
        XCTFail()
        return
      }
      XCTAssertNil(object)
      XCTAssertEqual(response, httpURLResponse)
      XCTAssertEqual(error as NSError, expectedError as NSError)
      expectation.fulfill()
    }

    waitForExpectations(timeout: 2.0, handler: nil)
  }

  func testParseResponseWithResponseObjectAndReturnedError() {
    let expectation = self.expectation(description: "parseResponse")

    let httpURLResponse = HTTPURLResponse()
    let json: [AnyHashable: Any] = STPTestUtils.jsonNamed("CardSource")!
    let body = try? JSONSerialization.data(withJSONObject: json, options: [])
    let errorParameter: NSError? = NSError(
      domain: NSURLErrorDomain, code: NSURLErrorUnknown, userInfo: nil)

    APIRequest<STPCard>.parseResponse(
      httpURLResponse,
      body: body,
      error: errorParameter
    ) { (object: STPCard?, response, error) in
      guard let error = error else {
        XCTFail()
        return
      }
      XCTAssertNil(object)
      XCTAssertEqual(response, httpURLResponse)
      XCTAssertEqual(error as NSError, errorParameter)
      expectation.fulfill()
    }

    waitForExpectations(timeout: 2.0, handler: nil)
  }
}
