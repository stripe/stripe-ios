//
//  NSArray+StripeTest.swift
//  StripeiOS Tests
//
//  Created by Jack Flintermann on 1/19/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

@testable@_spi(InternalOnlyAPI) import Stripe
@testable@_spi(InternalOnlyAPI) import StripeCore
@testable@_spi(InternalOnlyAPI) import StripePayments
@testable@_spi(InternalOnlyAPI) import StripePaymentSheet
@testable@_spi(InternalOnlyAPI) import StripePaymentsUI
import XCTest

class Array_StripeTest: XCTestCase {
    func test_arrayByRemovingNulls_removesNullsDeeply() {
        let array: [Any] = [
            "id",
            NSNull(),  // null in root
            [
                "user": "user_123",
                "country": NSNull(),  // null in dictionary
                "nicknames": ["john", "johnny", NSNull()],
                "profiles": [
                    "facebook": "fb_123",
                    "twitter": NSNull(),
                ],
            ],
            [
                NSNull(),  // null in array
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

        XCTAssertEqual(result as NSArray, [] as NSArray)
    }
}
