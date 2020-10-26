//
//  NSArray+StripeTest.swift
//  Stripe
//
//  Created by Jack Flintermann on 1/19/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

@testable import Stripe

class Array_StripeTest: XCTestCase {
  func test_boundSafeObjectAtIndex_emptyArray() {
    let test: [Any] = []
    XCTAssertNil(test.stp_boundSafeObject(at: 5))
  }

  func test_boundSafeObjectAtIndex_tooHighIndex() {
    let test = [NSNumber(value: 1), NSNumber(value: 2), NSNumber(value: 3)]
    XCTAssertNil(test.stp_boundSafeObject(at: 5))
  }

  func test_boundSafeObjectAtIndex_withinBoundsIndex() {
    let test = [NSNumber(value: 1), NSNumber(value: 2), NSNumber(value: 3)]
    XCTAssertEqual(test.stp_boundSafeObject(at: 1) as! NSNumber, NSNumber(value: 2))
  }

  func test_arrayByRemovingNulls_removesNullsDeeply() {
    let array: [Any] = [
      "id",
      NSNull() /* null in root */,
      [
        "user": "user_123",
        "country": NSNull() /* null in dictionary */,
        "nicknames": ["john", "johnny", NSNull()],
        "profiles": [
          "facebook": "fb_123",
          "twitter": NSNull(),
        ],
      ],
      [
        NSNull() /* null in array */,
        [
          "id": "fee_123",
          "frequency": NSNull(),
        ],
        ["payment", NSNull()],
      ],
    ]

    let expected: [Any] = [
      "id",
      [
        "user": "user_123",
        "nicknames": ["john", "johnny"],
        "profiles": [
          "facebook": "fb_123"
        ],
      ],
      [
        [
          "id": "fee_123"
        ], ["payment"],
      ],
    ]

    let result = array.stp_arrayByRemovingNulls()

    XCTAssertEqual(result as NSArray, expected as NSArray)
  }

  func test_arrayByRemovingNulls_keepsEmptyLeaves() {
    let array = [NSNull()]
    let result = array.stp_arrayByRemovingNulls()

    XCTAssertEqual(result, [])
  }
}
