//
//  Dictionary+StripeTests.swift
//  StripeCoreTests
//
//  Created by Mel Ludowise on 6/16/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP)@testable import StripeCore
import XCTest

final class Dictionary_StripeTests: XCTestCase {
    func testJsonEncodeNestedDicts() {
        let input: [String: Any] = [
            "string": "some_string",
            "int": 0,
            "float": Float(0.1),
            "nested_string_dict": [
                "string": "some_other_string",
                "int": 1,
                "float": Float(0.5),
            ],
        ]

        let output = input.jsonEncodeNestedDicts(options: .sortedKeys)

        XCTAssertEqual(output.count, 4)
        XCTAssertEqual(output["string"] as? String, "some_string")
        XCTAssertEqual(output["int"] as? Int, 0)
        XCTAssertEqual(output["float"] as? Float, 0.1)
        XCTAssertEqual(
            output["nested_string_dict"] as? String,
            "{\"float\":0.5,\"int\":1,\"string\":\"some_other_string\"}"
        )
    }
}
