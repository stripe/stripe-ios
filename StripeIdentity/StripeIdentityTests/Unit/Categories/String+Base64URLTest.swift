//
//  String+Base64URLTest.swift
//  StripeIdentityTests
//
//  Created by Stripe on 7/23/26.
//

import Foundation
import XCTest

@testable import StripeIdentity

final class String_Base64URLTest: XCTestCase {
    func testBase64URLDecodedData() {
        XCTAssertEqual(
            "dGVzdE5vbmNlQWJjZGVmZ2hpamtsbW5vcHE".base64URLDecodedData,
            Data("testNonceAbcdefghijklmnopq".utf8)
        )
        XCTAssertNil("not+base64url".base64URLDecodedData)
    }

    func testBase64URLEncodedString() {
        XCTAssertEqual(Data([0xfb, 0xff]).base64URLEncodedString, "-_8")
    }
}
