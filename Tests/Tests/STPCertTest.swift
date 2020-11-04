//
//  STPCertTest.swift
//  Stripe
//
//  Created by Phillip Cohen on 4/14/14.
//
//

import XCTest

@testable import Stripe

let STPExamplePublishableKey = "bad_key"

class STPCertTest: XCTestCase {
  func testNoError() {
    let expectation = self.expectation(description: "Token creation")
    let client = STPAPIClient(publishableKey: STPExamplePublishableKey)
    client.createToken(
      withParameters: [:]) { token, error in
        expectation.fulfill()
        // Note that this API request *will* fail, but it will return error
        // messages from the server and not be blocked by local cert checks
        XCTAssertNil(token, "Expected no token")
        XCTAssertNotNil(error, "Expected error")
      }
    waitForExpectations(timeout: 20.0, handler: nil)
  }

  func testExpired() {
    createToken(
      withBaseURL: URL(string: "https://testssl-expire-r2i2.disig.sk/index.en.html")
    ) { token, error in
      XCTAssertNil(token, "Token should be nil.")
      XCTAssertEqual((error as NSError?)?.domain, "NSURLErrorDomain")
      XCTAssertNotNil(
        (error as NSError?)?.userInfo["NSURLErrorFailingURLPeerTrustErrorKey"],
        "There should be a secTustRef for Foundation HTTPS errors")
    }
  }

  func testMismatched() {
    createToken(
      withBaseURL: URL(string: "https://mismatched.stripe.com")
    ) { token, error in
      XCTAssertNil(token, "Token should be nil.")
      XCTAssertEqual((error as NSError?)?.domain, "NSURLErrorDomain")
    }
  }

  // helper method
  func createToken(withBaseURL baseURL: URL?, completion: @escaping STPTokenCompletionBlock) {
    let expectation = self.expectation(description: "Token creation")
    let client = STPAPIClient(publishableKey: STPExamplePublishableKey)
    client.apiURL = baseURL
    client.createToken(
      withParameters: [:]) { token, error in
        expectation.fulfill()
        completion(token, error)
      }
    waitForExpectations(timeout: 20.0, handler: nil)
  }
}
