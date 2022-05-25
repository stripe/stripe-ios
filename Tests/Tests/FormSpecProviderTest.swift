//
//  FormSpecProviderTest.swift
//  StripeiOS Tests
//
//  Created by Yuki Tokuhiro on 3/7/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import XCTest
@_spi(STP) @testable import Stripe
@_spi(STP) @testable import StripeUICore

class FormSpecProviderTest: XCTestCase {
    func testLoadsJSON() throws {
        let e = expectation(description: "Loads form specs file")
        let sut = FormSpecProvider()
        sut.load { loaded in
            XCTAssertTrue(loaded)
            e.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
        
        // Sanity check that card doesn't exist
        XCTAssertNil(sut.formSpec(for: "card"))
        // ...but EPS exists
        guard let eps = sut.formSpec(for: "eps") else {
            XCTFail()
            return
        }
        XCTAssertEqual(eps.fields.count, 2)
        XCTAssertEqual(eps.fields.first, .name(FormSpec.NameFieldSpec(apiPath:["v1":"billing_details[name]"], label: nil)))

        // ...and iDEAL has the correct dropdown spec
        guard let ideal = sut.formSpec(for: "ideal"),
              case .name = ideal.fields[0],
              case let .selector(selector) = ideal.fields[1] else {
                  XCTFail()
            return
        }
        XCTAssertEqual(selector.apiPath?["v1"], "ideal[bank]")
        XCTAssertEqual(selector.items.count, 13)
    }
}
