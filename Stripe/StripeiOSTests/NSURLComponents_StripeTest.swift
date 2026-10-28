//
//  NSURLComponents_StripeTest.swift
//  StripeiOS Tests
//
//  Created by Yuki Tokuhiro on 5/24/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

@testable@_spi(InternalOnlyAPI) import Stripe
@testable@_spi(InternalOnlyAPI) import StripeCore
@testable@_spi(InternalOnlyAPI) import StripePayments
@testable@_spi(InternalOnlyAPI) import StripePaymentSheet
@testable@_spi(InternalOnlyAPI) import StripePaymentsUI
import XCTest

class NSURLComponents_StripeTest: XCTestCase {
    func testCaseInsensitiveSchemeComparison() {
        let lhs = NSURLComponents(string: "com.bar.foo://host")!
        let rhs = NSURLComponents(string: "COM.BAR.FOO://HOST")!
        XCTAssert(lhs.stp_matchesURLComponents(lhs))  // sanity
        XCTAssert(lhs.stp_matchesURLComponents(rhs))
        XCTAssert(rhs.stp_matchesURLComponents(lhs))
    }

    func testMatchesURLsWithQueryString() {
        // e.g. STPSourceFunctionalTest passes "https://shop.example.com/crtABC" for the return_url,
        // but the Source object returned by the API comes has "https://shop.example.com/crtABC?redirect_merchant_name=xctest"
        let expectedComponents = NSURLComponents(
            string: "https://shop.example.com/crtABC?redirect_merchant_name=xctest"
        )!
        let components = NSURLComponents(string: "https://shop.example.com/crtABC")!
        XCTAssertTrue(components.stp_matchesURLComponents(expectedComponents))
    }

    func testMatchesURLWithNilParameters() {
        let nil1 = NSURLComponents(string: "")!
        let nil2 = NSURLComponents(string: "")!
        XCTAssert(nil1.stp_matchesURLComponents(nil2))
    }
}
