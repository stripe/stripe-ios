//
//  LinkSecureCookieStoreTests.swift
//  StripeiOS Tests
//
//  Created by Ramon Torres on 12/22/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

@testable import Stripe
@testable import StripePaymentSheet
import XCTest

class LinkSecureCookieStoreTests: XCTestCase {

    static let testKey: LinkCookieKey = .session

    let cookieStore: LinkSecureCookieStore = .shared

    func testWrite() {
        cookieStore.write(key: Self.testKey, value: "cookie_value")

        XCTAssertEqual(cookieStore.read(key: Self.testKey), "cookie_value")
    }

    func testWrite_allowSyncTrue() {
        cookieStore.write(key: Self.testKey, value: "cookie_value", allowSync: true)

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

    func testDelete_allowSyncTrue() {
        cookieStore.write(key: Self.testKey, value: "cookie_value", allowSync: true)
        cookieStore.delete(key: Self.testKey)

        XCTAssertNil(cookieStore.read(key: Self.testKey))
    }

    // MARK: Session cookies

    func testFormattedSessionCookies() {
        cookieStore.write(key: .session, value: "cookie_value")
        XCTAssertEqual(cookieStore.formattedSessionCookies(), [
            "verification_session_client_secrets": ["cookie_value"]
        ])

        cookieStore.delete(key: .session)
        XCTAssertNil(cookieStore.formattedSessionCookies())
    }

    func testUpdateSessionCookie() {
        cookieStore.updateSessionCookie(with: "top_secret")
        XCTAssertEqual(cookieStore.read(key: .session), "top_secret")

        // Updating with a `nil` client secret should be a no-op.
        cookieStore.updateSessionCookie(with: nil)
        XCTAssertEqual(cookieStore.read(key: .session), "top_secret")

        cookieStore.updateSessionCookie(with: "")
        XCTAssertNil(cookieStore.read(key: .session))
    }

}
