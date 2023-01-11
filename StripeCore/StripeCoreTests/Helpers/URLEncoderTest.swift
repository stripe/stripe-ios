//
//  URLEncoderTest.swift
//  StripeCoreTests
//
//  Created by Mel Ludowise on 5/26/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

@_spi(STP) import StripeCore
import XCTest

final class URLEncoderTest: XCTestCase {
    func testStringByReplacingSnakeCaseWithCamelCase() {
        let camelCase = URLEncoder.convertToCamelCase(snakeCase: "test_1_2_34_test")
        XCTAssertEqual("test1234Test", camelCase)
    }

    func testStringByReplacingCamelCaseWithSnakeCase() {
        let snakeCase = URLEncoder.convertToSnakeCase(camelCase: "test1234Test")
        XCTAssertEqual("test1234_test", snakeCase)
        let snakeCase2 = URLEncoder.convertToSnakeCase(camelCase: "testUrlTest")
        XCTAssertEqual("test_url_test", snakeCase2)
    }

    func testQueryStringWithBadFields() {
        let params = [
            "foo]": "bar",
            "baz": "qux[",
            "woo;": ";hoo",
        ]
        let result = URLEncoder.queryString(from: params)
        XCTAssertEqual(result, "baz=qux%5B&foo%5D=bar&woo%3B=%3Bhoo")
    }

    func testQueryStringFromParameters() {
        let params =
            [
                "foo": "bar",
                "baz": [
                    "qux": NSNumber(value: 1),
                ],
            ] as [String: AnyHashable]
        let result = URLEncoder.queryString(from: params)
        XCTAssertEqual(result, "baz[qux]=1&foo=bar")
    }

    func testPushProvisioningQueryStringFromParameters() {
        let params = [
            "ios": [
                "certificates": ["cert1", "cert2"],
                "nonce": "123mynonce",
                "nonce_signature": "sig",
            ],
        ]
        let result = URLEncoder.queryString(from: params)
        XCTAssertEqual(
            result,
            "ios[certificates][0]=cert1&ios[certificates][1]=cert2&ios[nonce]=123mynonce&ios[nonce_signature]=sig"
        )
    }
}
