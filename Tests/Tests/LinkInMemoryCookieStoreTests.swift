//
//  LinkInMemoryCookieStoreTests.swift
//  StripeiOS Tests
//
//  Created by Ramon Torres on 12/21/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import XCTest
@testable import Stripe

class LinkInMemoryCookieStoreTests: XCTestCase {

    static let testKey: String = "test-key"

    func testWrite() {
        let sut = makeSUT()
        sut.write(key: Self.testKey, value: "cookie_value")

        XCTAssertEqual(sut.read(key: Self.testKey), "cookie_value")
    }

    func testWrite_overwriting() {
        let sut = makeSUT()
        sut.write(key: Self.testKey, value: "cookie_value")
        sut.write(key: Self.testKey, value: "new_cookie_value")

        XCTAssertEqual(sut.read(key: Self.testKey), "new_cookie_value")
    }

    func testDelete() {
        let sut = makeSUT()
        sut.write(key: Self.testKey, value: "cookie_value")
        sut.delete(key: Self.testKey)

        XCTAssertNil(sut.read(key: Self.testKey))
    }

    // MARK: Session cookies

    func testFormattedSessionCookies() {
        let sut = makeSUT()

        sut.write(key: sut.sessionCookieKey, value: "cookie_value")
        XCTAssertEqual(sut.formattedSessionCookies(), [
            "verification_session_client_secrets": ["cookie_value"]
        ])

        sut.delete(key: sut.sessionCookieKey)
        XCTAssertNil(sut.formattedSessionCookies())
    }

    func testUpdateSessionCookie() {
        let sut = makeSUT()
        sut.updateSessionCookie(with: "top_secret")
        XCTAssertEqual(sut.read(key: sut.sessionCookieKey), "top_secret")

        sut.updateSessionCookie(with: nil)
        XCTAssertEqual(sut.read(key: sut.sessionCookieKey), "top_secret")

        sut.updateSessionCookie(with: "")
        XCTAssertNil(sut.read(key: sut.sessionCookieKey))
    }

}

extension LinkInMemoryCookieStoreTests {

    func makeSUT() -> LinkInMemoryCookieStore {
        return LinkInMemoryCookieStore()
    }

}
