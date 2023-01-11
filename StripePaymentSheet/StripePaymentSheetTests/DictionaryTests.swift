//
//  DictionaryTests.swift
//  StripePaymentSheetTests
//
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
import XCTest

@_spi(STP) @testable import StripePaymentSheet

class DictionaryTests: XCTestCase {

    func testParseLUXEJSONPath() {
        XCTAssertEqual(Dictionary.stp_parseLUXEJSONPath(""), [])
        XCTAssertEqual(Dictionary.stp_parseLUXEJSONPath("next_action"), ["next_action"])
        XCTAssertEqual(Dictionary.stp_parseLUXEJSONPath("next_action[k1][k2]"), ["next_action", "k1", "k2"])
    }

    func testForLUXEJSONPath() {
        let input: [AnyHashable: Any] = [ "next_action": ["display_details":
                                                            [
                                                                "hosted_voucher_url": "https://payments.stripe.com/pm/v/test",
                                                                "expires_at": 123456,
                                                            ],
                                                          ],
                                          "other_key": "value2", ]

        XCTAssertEqual(input.stp_forLUXEJSONPath("other_key") as? String, "value2")
        XCTAssertEqual(input.stp_forLUXEJSONPath("next_action[display_details][hosted_voucher_url]") as? String, "https://payments.stripe.com/pm/v/test")
        XCTAssertEqual(input.stp_forLUXEJSONPath("next_action[display_details][expires_at]") as? Int, 123456)

        guard let dict = input.stp_forLUXEJSONPath("next_action[display_details]") as? [AnyHashable: Any] else {
            XCTFail("")
            return
        }
        XCTAssertEqual(dict["hosted_voucher_url"] as? String, "https://payments.stripe.com/pm/v/test" )
        XCTAssertEqual(dict["expires_at"] as? Int, 123456)

        XCTAssertNil(input.stp_forLUXEJSONPath("next_action[display_details][doesNotExist]"))
        XCTAssertNil(input.stp_forLUXEJSONPath(""))
    }
}
