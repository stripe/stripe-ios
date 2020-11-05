//
//  NSString+StripeTest.swift
//  Stripe
//
//  Created by Ben Guo on 3/22/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//
@testable import Stripe

class NSString_StripeTest: XCTestCase {
  func testSafeSubstringToIndex() {
    XCTAssertEqual("foo".stp_safeSubstring(to: 0), "")
    XCTAssertEqual("foo".stp_safeSubstring(to: 500), "foo")
    XCTAssertEqual("foo".stp_safeSubstring(to: 1), "f")
    XCTAssertEqual("".stp_safeSubstring(to: 0), "")
    XCTAssertEqual("".stp_safeSubstring(to: 1), "")
  }

  func testSafeSubstringFromIndex() {
    XCTAssertEqual("foo".stp_safeSubstring(from: 0), "foo")
    XCTAssertEqual("foo".stp_safeSubstring(from: 1), "oo")
    XCTAssertEqual("foo".stp_safeSubstring(from: 3), "")
    XCTAssertEqual("".stp_safeSubstring(from: 0), "")
    XCTAssertEqual("".stp_safeSubstring(from: 1), "")
  }

  func testStringByRemovingSuffix() {
    XCTAssertEqual("foobar".stp_string(byRemovingSuffix: "bar"), "foo")
    XCTAssertEqual("foobar".stp_string(byRemovingSuffix: "baz"), "foobar")
    XCTAssertEqual("foobar".stp_string(byRemovingSuffix: nil), "foobar")
    XCTAssertEqual("foobar".stp_string(byRemovingSuffix: "foobar"), "")
    XCTAssertEqual("foobar".stp_string(byRemovingSuffix: ""), "foobar")
    XCTAssertEqual("foobar".stp_string(byRemovingSuffix: "oba"), "foobar")

    XCTAssertEqual("foobar☺¿".stp_string(byRemovingSuffix: "bar☺¿"), "foo")
    XCTAssertEqual("foobar☺¿".stp_string(byRemovingSuffix: "bar¿"), "foobar☺¿")

    XCTAssertEqual("foobar\u{202C}".stp_string(byRemovingSuffix: "bar"), "foobar\u{202C}")
    XCTAssertEqual("foobar\u{202C}".stp_string(byRemovingSuffix: "bar\u{202C}"), "foo")

    // e + \u0041 => é
    XCTAssertEqual("foobare\u{0301}".stp_string(byRemovingSuffix: "bare"), "foobare\u{0301}")
    XCTAssertEqual("foobare\u{0301}".stp_string(byRemovingSuffix: "bare\u{0301}"), "foo")
    XCTAssertEqual("foobare".stp_string(byRemovingSuffix: "bare\u{0301}"), "foobare")

  }
}
