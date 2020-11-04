//
//  NSDictionary+StripeTest.swift
//  Stripe
//
//  Created by Joey Dong on 7/24/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

@testable import Stripe

class NSDictionary_StripeTest: XCTestCase {
  // MARK: - dictionaryByRemovingNullsValidatingRequiredFields
  func test_dictionaryByRemovingNulls_removesNullsDeeply() {
    let dictionary =
      [
        "id": "card_123",
        "tokenization_method": NSNull() /* null in root */,
        "metadata": [
          "user": "user_123",
          "country": NSNull() /* null in dictionary */,
          "nicknames": ["john", "johnny", NSNull()],
          "profiles": [
            "facebook": "fb_123",
            "twitter": NSNull(),
          ],
        ],
        "fees": [
          NSNull() /* null in array */,
          [
            "id": "fee_123",
            "frequency": NSNull(),
          ],
          ["payment", NSNull()],
        ],
      ] as NSDictionary

    let expected =
      [
        "id": "card_123",
        "metadata": [
          "user": "user_123",
          "nicknames": ["john", "johnny"],
          "profiles": [
            "facebook": "fb_123"
          ],
        ],
        "fees": [
          [
            "id": "fee_123"
          ], ["payment"],
        ],
      ] as NSDictionary

    let result = dictionary.stp_dictionaryByRemovingNulls() as NSDictionary
    XCTAssertEqual(result, expected)
  }

  func test_dictionaryByRemovingNullsValidatingRequiredFields_keepsEmptyLeaves() {
    let dictionary =
      [
        "id": NSNull()
      ] as NSDictionary
    let result = dictionary.stp_dictionaryByRemovingNulls() as NSDictionary

    XCTAssertEqual(result, [:])
  }

  // MARK: - dictionaryByRemovingNonStrings
  func test_dictionaryByRemovingNonStrings_basicCases() {
    // Empty dictionary
    var dictionary = [:] as NSDictionary
    var expected = [:] as NSDictionary
    var result = dictionary.stp_dictionaryByRemovingNonStrings() as NSDictionary
    XCTAssertEqual(result, expected)

    // Regular case
    dictionary =
      [
        "user": "user_123",
        "nicknames": "John, Johnny",
      ] as NSDictionary
    expected =
      [
        "user": "user_123",
        "nicknames": "John, Johnny",
      ] as NSDictionary
    result = dictionary.stp_dictionaryByRemovingNonStrings() as NSDictionary
    XCTAssertEqual(result, expected)

    // Strips non-NSString keys and values
    dictionary =
      [
        "user": "user_123",
        "nicknames": "John, Johnny",
        "profiles": NSNull(),
        NSNull(): "San Francisco, CA",
        NSNull(): NSNull(),
        "age": NSNumber(value: 21),
        NSNumber(value: 21): "age",
        NSNumber(value: 21): NSNumber(value: 21),
        "fees": [
          "plan": "monthly"
        ],
        "visits": ["january", "february"],
      ] as NSDictionary
    expected =
      [
        "user": "user_123",
        "nicknames": "John, Johnny",
      ] as NSDictionary
    result = dictionary.stp_dictionaryByRemovingNonStrings() as NSDictionary
    XCTAssertEqual(result, expected)
  }

  // MARK: - Getters
  func testArrayForKey() {
    let dict =
      [
        "a": ["foo"]
      ] as NSDictionary

    XCTAssertEqual(dict.stp_array(forKey: "a") as! [String], ["foo"])
    XCTAssertNil(dict.stp_array(forKey: "b"))
  }

  func testBoolForKey() {
    let dict =
      [
        "a": NSNumber(value: 1),
        "b": NSNumber(value: 0),
        "c": "true",
        "d": "false",
        "e": "1",
        "f": "foo",
      ] as NSDictionary

    XCTAssertTrue(dict.stp_bool(forKey: "a", or: false))
    XCTAssertFalse(dict.stp_bool(forKey: "b", or: true))
    XCTAssertTrue(dict.stp_bool(forKey: "c", or: false))
    XCTAssertFalse(dict.stp_bool(forKey: "d", or: true))
    XCTAssertTrue(dict.stp_bool(forKey: "e", or: false))
    XCTAssertFalse(dict.stp_bool(forKey: "f", or: false))
  }

  func testIntForKey() {
    let dict =
      [
        "a": NSNumber(value: 1),
        "b": NSNumber(value: -1),
        "c": "1",
        "d": "-1",
        "e": "10.0",
        "f": "10.5",
        "g": NSNumber(value: 10.0),
        "h": NSNumber(value: 10.5),
        "i": "foo",
      ] as NSDictionary

    XCTAssertEqual(dict.stp_int(forKey: "a", or: 0), 1)
    XCTAssertEqual(dict.stp_int(forKey: "b", or: 0), -1)
    XCTAssertEqual(dict.stp_int(forKey: "c", or: 0), 1)
    XCTAssertEqual(dict.stp_int(forKey: "d", or: 0), -1)
    XCTAssertEqual(dict.stp_int(forKey: "e", or: 0), 10)
    XCTAssertEqual(dict.stp_int(forKey: "f", or: 0), 10)
    XCTAssertEqual(dict.stp_int(forKey: "g", or: 0), 10)
    XCTAssertEqual(dict.stp_int(forKey: "h", or: 0), 10)
    XCTAssertEqual(dict.stp_int(forKey: "i", or: 0), 0)
  }

  func testDateForKey() {
    let dict =
      [
        "a": NSNumber(value: 0),
        "b": "0",
      ] as NSDictionary
    let expectedDate = Date(timeIntervalSince1970: 0)

    XCTAssertEqual(dict.stp_date(forKey: "a"), expectedDate)
    XCTAssertEqual(dict.stp_date(forKey: "b"), expectedDate)
    XCTAssertNil(dict.stp_date(forKey: "c"))
  }

  func testDictionaryForKey() {
    let dict =
      [
        "a": [
          "foo": "bar"
        ]
      ] as NSDictionary

    XCTAssertEqual(
      dict.stp_dictionary(forKey: "a")! as NSDictionary,
      [
        "foo": "bar"
      ])
    XCTAssertNil(dict.stp_dictionary(forKey: "b"))
  }

  func testNumberForKey() {
    let dict =
      [
        "a": NSNumber(value: 1)
      ] as NSDictionary

    XCTAssertEqual(dict.stp_number(forKey: "a"), NSNumber(value: 1))
    XCTAssertNil(dict.stp_number(forKey: "b"))
  }

  func testStringForKey() {
    let dict =
      [
        "a": "foo"
      ] as NSDictionary
    XCTAssertEqual(dict.stp_string(forKey: "a"), "foo")
    XCTAssertNil(dict.stp_string(forKey: "b"))
  }

  func testURLForKey() {
    let dict =
      [
        "a": "https://example.com",
        "b": "not a url",
      ] as NSDictionary
    XCTAssertEqual(dict.stp_url(forKey: "a"), URL(string: "https://example.com"))
    XCTAssertNil(dict.stp_url(forKey: "b"))
    XCTAssertNil(dict.stp_url(forKey: "c"))
  }
}
