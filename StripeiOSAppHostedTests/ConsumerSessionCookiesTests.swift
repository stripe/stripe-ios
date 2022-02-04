//
//  ConsumerSessionCookiesTests.swift
//  StripeiOS Tests
//
//  Created by Cameron Sabol on 11/4/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import XCTest
@testable import Stripe

class ConsumerSessionCookiesTests: XCTestCase {

    let cookieStore = LinkInMemoryCookieStore()

    func testCookieWrite() {
        let cookieOperation = ConsumerSession.CookiesOperation(operationType: .add,
                                                               verificationSessionClientSecret: "top_secret",
                                                               allResponseFields: [:])
        cookieOperation.apply(withStore: cookieStore)
        XCTAssertEqual(
            cookieStore.formattedSessionCookies(),
            ["verification_session_client_secrets": ["top_secret"]]
        )
    }
    
    func testCookieDelete() {
        let addCookieOperation = ConsumerSession.CookiesOperation(operationType: .add,
                                                                  verificationSessionClientSecret: "top_secret",
                                                                  allResponseFields: [:])
        addCookieOperation.apply(withStore: cookieStore)
        let deleteCookieOperation = ConsumerSession.CookiesOperation(operationType: .remove,
                                                                     verificationSessionClientSecret: "top_secret",
                                                                     allResponseFields: [:])
        deleteCookieOperation.apply(withStore: cookieStore)
        XCTAssertNil(cookieStore.formattedSessionCookies())
    }
    
    func testCookieDeleteOnlyDeletesMatchingValue() {
        let addCookieOperation = ConsumerSession.CookiesOperation(operationType: .add,
                                                                  verificationSessionClientSecret: "top_secret",
                                                                  allResponseFields: [:])
        addCookieOperation.apply(withStore: cookieStore)
        let deleteCookieOperation = ConsumerSession.CookiesOperation(operationType: .remove,
                                                                     verificationSessionClientSecret: "declassified",
                                                                     allResponseFields: [:])
        deleteCookieOperation.apply(withStore: cookieStore)
        XCTAssertEqual(
            cookieStore.formattedSessionCookies(),
            ["verification_session_client_secrets": ["top_secret"]]
        )
    }
    
    func testCookieOverwrite() {
        let cookieOperation = ConsumerSession.CookiesOperation(operationType: .add,
                                                               verificationSessionClientSecret: "top_secret",
                                                               allResponseFields: [:])
        cookieOperation.apply(withStore: cookieStore)
        
        let cookieOperation2 = ConsumerSession.CookiesOperation(operationType: .add,
                                                                verificationSessionClientSecret: "topper_secret",
                                                                allResponseFields: [:])
        cookieOperation2.apply(withStore: cookieStore)
        XCTAssertEqual(
            cookieStore.formattedSessionCookies(),
            ["verification_session_client_secrets": ["topper_secret"]]
        )
    }
}
