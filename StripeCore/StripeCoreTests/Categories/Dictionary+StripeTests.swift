//
//  Dictionary+StripeTests.swift
//  StripeCoreTests
//
//  Created by Mel Ludowise on 6/16/22.
//

import Foundation
import XCTest
@_spi(STP) @testable import StripeCore

final class Dictionary_StripeTests: XCTestCase {
    func testJsonEncodeNestedDicts() {
        let input: [String: Any] = [
            "string": "some_string",
            "int": 0,
            "float": Float(0.1),
            "nested_string_dict": [
                "string": "some_other_string",
                "int": 1,
                "float": Float(0.5)
            ],
        ]

        let output = input.jsonEncodeNestedDicts(options: .sortedKeys)

        XCTAssertEqual(output.count, 4)
        XCTAssertEqual(output["string"] as? String, "some_string")
        XCTAssertEqual(output["int"] as? Int, 0)
        XCTAssertEqual(output["float"] as? Float, 0.1)
        XCTAssertEqual(output["nested_string_dict"] as? String, "{\"float\":0.5,\"int\":1,\"string\":\"some_other_string\"}")
    }

    func testParseLUXEJSONPath() {
        XCTAssertEqual(Dictionary.stp_parseLUXEJSONPath(""), [])
        XCTAssertEqual(Dictionary.stp_parseLUXEJSONPath("next_action"), ["next_action"])
        XCTAssertEqual(Dictionary.stp_parseLUXEJSONPath("next_action[k1][k2]"), ["next_action", "k1", "k2"])
    }

    func testForLUXEJSONPath() {
        let input: [AnyHashable: Any] = [ "next_action" : ["display_details":
                                                            [
                                                                "hosted_voucher_url":"https://payments.stripe.com/pm/v/test",
                                                                "expires_at": 123456
                                                            ]
                                                          ],
                                          "other_key": "value2"]

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
