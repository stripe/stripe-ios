//
//  NSMutableURLRequest+StripeTest.swift
//  StripeCoreTests
//
//  Created by Ben Guo on 4/22/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

@_spi(STP) import StripeCore
import XCTest

class NSMutableURLRequest_StripeTest: XCTestCase {
    func testAddParametersToURL_noQuery() {
        var request: URLRequest?
        if let url = URL(string: "https://example.com") {
            request = URLRequest(url: url)
        }
        request?.stp_addParameters(toURL: [
            "foo": "bar",
        ])

        XCTAssertEqual(request?.url?.absoluteString, "https://example.com?foo=bar")
    }

    func testAddParametersToURL_hasQuery() {
        var request: URLRequest?
        if let url = URL(string: "https://example.com?a=b") {
            request = URLRequest(url: url)
        }
        request?.stp_addParameters(toURL: [
            "foo": "bar",
        ])

        XCTAssertEqual(request?.url?.absoluteString, "https://example.com?a=b&foo=bar")
    }

    func testAddParametersToURL_encodesSpecialCharacters() {
        let baseURL = URL(string: "https://example.com")!
        struct TestCase {
            let parameters: [String: Any]
            let expectedURL: String
        }
        // These test cases expected values were generated using SDK v23.22.0 pre-iOS 17.
        // They don't comply with RFC 3986, but they are correct/expected in the sense that they've worked in practice when used w/ the Stripe API.
        let testcases: [TestCase] = [
            .init(parameters: ["~!@W#$%^&*()-=+[]{}/?\\": "~!@W#$%^&*()-=+[]{}/?\\"], expectedURL: "https://example.com?~%21%40W%23%24%25%5E%26%2A%28%29-%3D%2B%5B%5D%7B%7D/?%5C=~%21%40W%23%24%25%5E%26%2A%28%29-%3D%2B%5B%5D%7B%7D/?%5C"),
            .init(parameters: ["name": "John Doe"], expectedURL: "https://example.com?name=John%20Doe"),
            .init(parameters: ["bool_flag": true], expectedURL: "https://example.com?bool_flag=true"),
            .init(parameters: ["return_url": "https://foo.com?src=bar"], expectedURL: "https://example.com?return_url=https%3A//foo.com?src%3Dbar"),
            .init(parameters: [
                "mpe_config": [
                    "nested_list": ["A", "B", "C"],
                    "appearance_config": [
                        "toggle": true,
                    ],
                    "name": "John Doe",
                    "return_url": "https://foo.com?src=bar",
                ],
            ], expectedURL: "https://example.com?mpe_config%5Bappearance_config%5D%5Btoggle%5D=true&mpe_config%5Bname%5D=John%20Doe&mpe_config%5Bnested_list%5D%5B0%5D=A&mpe_config%5Bnested_list%5D%5B1%5D=B&mpe_config%5Bnested_list%5D%5B2%5D=C&mpe_config%5Breturn_url%5D=https%3A//foo.com?src%3Dbar"),
            .init(parameters: ["locale": "en-US"], expectedURL: "https://example.com?locale=en-US"),
        ]
        for testcase in testcases {
            var request = URLRequest(url: baseURL)
            request.stp_addParameters(toURL: testcase.parameters)
            XCTAssertEqual(request.url?.absoluteString, testcase.expectedURL)
        }
    }
}
