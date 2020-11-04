//  NSMutableURLRequest+StripeTest.swift
//  Stripe
//
//  Created by Ben Guo on 4/22/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//
@testable import Stripe

class NSMutableURLRequest_StripeTest: XCTestCase {
  func testAddParametersToURL_noQuery() {
    var request: NSMutableURLRequest?
    if let url = URL(string: "https://example.com") {
      request = NSMutableURLRequest(url: url)
    }
    request?.stp_addParameters(toURL: [
      "foo": "bar"
    ])

    XCTAssertEqual(request?.url?.absoluteString, "https://example.com?foo=bar")
  }

  func testAddParametersToURL_hasQuery() {
    var request: NSMutableURLRequest?
    if let url = URL(string: "https://example.com?a=b") {
      request = NSMutableURLRequest(url: url)
    }
    request?.stp_addParameters(toURL: [
      "foo": "bar"
    ])

    XCTAssertEqual(request?.url?.absoluteString, "https://example.com?a=b&foo=bar")
  }
}
