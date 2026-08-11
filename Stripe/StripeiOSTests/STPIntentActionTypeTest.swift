//
//  STPIntentActionTypeTest.swift
//  StripeiOS Tests
//
//  Created by Cameron Sabol on 9/29/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import XCTest

@testable@_spi(STP) import Stripe
@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePayments
@testable@_spi(STP) import StripePaymentSheet
@testable@_spi(STP) import StripePaymentsUI

class STPIntentActionTypeTest: XCTestCase {

    func testTypeFromString() {
        XCTAssertEqual(
            STPIntentActionType(string: "redirect_to_url"),
            STPIntentActionType.redirectToURL
        )
        XCTAssertEqual(
            STPIntentActionType(string: "REDIRECT_TO_URL"),
            STPIntentActionType.redirectToURL
        )

        XCTAssertEqual(
            STPIntentActionType(string: "use_stripe_sdk"),
            STPIntentActionType.useStripeSDK
        )
        XCTAssertEqual(
            STPIntentActionType(string: "USE_STRIPE_SDK"),
            STPIntentActionType.useStripeSDK
        )

        XCTAssertEqual(
            STPIntentActionType(string: "mb_way_await_authorization"),
            STPIntentActionType.mbWayAwaitAuthorization
        )
        XCTAssertEqual(
            STPIntentActionType(string: "await_authorization"),
            STPIntentActionType.awaitAuthorization
        )

        XCTAssertEqual(
            STPIntentActionType(string: "garbage"),
            STPIntentActionType.unknown
        )
        XCTAssertEqual(
            STPIntentActionType(string: "GARBAGE"),
            STPIntentActionType.unknown
        )
    }

    func testMBAwaitAuthorizationDecoding() {
        let action = STPIntentAction.decodedObject(fromAPIResponse: [
            "type": "mb_way_await_authorization",
            "mb_way_await_authorization": [:],
        ])

        XCTAssertEqual(action?.type, .mbWayAwaitAuthorization)
    }

    func testAwaitAuthorizationDecoding() {
        let action = STPIntentAction.decodedObject(fromAPIResponse: [
            "type": "await_authorization",
            "await_authorization": [:],
        ])

        XCTAssertEqual(action?.type, .awaitAuthorization)
    }

}
