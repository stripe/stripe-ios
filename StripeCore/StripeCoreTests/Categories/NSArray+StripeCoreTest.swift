//
//  NSArray+StripeCoreTest.swift
//  StripeCoreTests
//
//  Created by Jack Flintermann on 1/19/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

@_spi(STP) import StripeCore
import XCTest

class Array_StripeCoreTest: XCTestCase {
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
        XCTAssertEqual(test.stp_boundSafeObject(at: 1), NSNumber(value: 2))
    }
}
