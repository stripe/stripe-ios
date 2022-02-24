//
//  LinkAccountServiceTests.swift
//  StripeiOS Tests
//
//  Created by Ramon Torres on 2/22/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import XCTest
@testable import Stripe

class LinkAccountServiceTests: XCTestCase {

    func testWrite() {
        let sut = makeSUT()
        XCTAssertTrue(sut.hasEmailLoggedOut(email: "user@example.com"))
        XCTAssertTrue(sut.hasEmailLoggedOut(email: "USER@EXAMPLE.COM"))
        XCTAssertFalse(sut.hasEmailLoggedOut(email: "user@example.net"))
    }

}

extension LinkAccountServiceTests {

    func makeSUT() -> LinkAccountService {
        let cookieStore = LinkInMemoryCookieStore()

        cookieStore.write(
            key: cookieStore.emailCookieKey,
            // SHA-256 hash for `user@example.com`
            value: "tMmiiTI7IaAcPpQPFQ65uMVCWH8av9jw4cwf/F5HVRQ="
        )

        return LinkAccountService(cookieStore: cookieStore)
    }

}
