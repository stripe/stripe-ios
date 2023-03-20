//  NSMutableURLRequest+StripeTest.swift
//  StripeCoreTests
//
//  Created by Ben Guo on 4/22/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

import XCTest

@_spi(STP) import StripeCore

class NSMutableURLRequest_StripeTest: XCTestCase {
    func testAddParametersToURL_noQuery() {
        var request: URLRequest?
        if let url = URL(string: "https://example.com") {
            request = URLRequest(url: url)
        }
        request?.stp_addParameters(toURL: [
            "foo": "bar"
        ])

        XCTAssertEqual(request?.url?.absoluteString, "https://example.com?foo=bar")
    }

    func testAddParametersToURL_hasQuery() {
        var request: URLRequest?
        if let url = URL(string: "https://example.com?a=b") {
            request = URLRequest(url: url)
        }
        request?.stp_addParameters(toURL: [
            "foo": "bar"
        ])

        XCTAssertEqual(request?.url?.absoluteString, "https://example.com?a=b&foo=bar")
    }
}
