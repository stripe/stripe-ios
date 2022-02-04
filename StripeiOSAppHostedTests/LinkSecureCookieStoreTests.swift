//
//  LinkSecureCookieStoreTests.swift
//  StripeiOS Tests
//
//  Created by Ramon Torres on 12/22/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import XCTest
@testable import Stripe

class LinkSecureCookieStoreTests: XCTestCase {

    static let testKey: String = "test-key"

    let cookieStore: LinkSecureCookieStore = .shared

    func testWrite() {
        cookieStore.write(key: Self.testKey, value: "cookie_value")

        XCTAssertEqual(cookieStore.read(key: Self.testKey), "cookie_value")
    }

    func testWrite_overwriting() {
        cookieStore.write(key: Self.testKey, value: "cookie_value")
        cookieStore.write(key: Self.testKey, value: "new_cookie_value")

        XCTAssertEqual(cookieStore.read(key: Self.testKey), "new_cookie_value")
    }

    func testDelete() {
        cookieStore.write(key: Self.testKey, value: "cookie_value")
        cookieStore.delete(key: Self.testKey)

        XCTAssertNil(cookieStore.read(key: Self.testKey))
    }

    func testDelete_withMatchingValue() {
        cookieStore.write(key: Self.testKey, value: "cookie_value")
        cookieStore.delete(key: Self.testKey, value: "cookie_value")

        XCTAssertNil(cookieStore.read(key: Self.testKey))
    }

    func testDelete_withNonMatchingValue() {
        cookieStore.write(key: Self.testKey, value: "cookie_value")
        cookieStore.delete(key: Self.testKey, value: "different_cookie_value")

        XCTAssertEqual(cookieStore.read(key: Self.testKey), "cookie_value")
    }

}
