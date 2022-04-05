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
        XCTAssertEqual(eps.elements.count, 1)
        XCTAssertEqual(eps.elements.first, .name)
        
        // ...and iDEAL has the correct dropdown spec
        guard let ideal = sut.formSpec(for: "ideal"),
              case .name = ideal.elements[0],
              case let .customDropdown(dropdown) = ideal.elements[1] else {
                  XCTFail()
            return
        }
        XCTAssertEqual(dropdown.paymentMethodDataPath, "ideal[bank]")
        XCTAssertEqual(dropdown.dropdownItems.count, 12)
    }
}
