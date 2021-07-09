//
//  DropdownFieldElementTest.swift
//  StripeiOS Tests
//
//  Created by Yuki Tokuhiro on 6/22/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import XCTest
@testable import Stripe

class DropdownFieldElementTest: XCTestCase {

    func testCountryCodeInitializer() throws {
        // Given a set of country codes where the codes alphabetical order != names alphabetical order...
        // e.g. [ES, NL] vs. [Netherlands, Spain]
        let countries = Set(["ES", "NL"])
        
        let e = expectation(description: "closure called")
        let country = DropdownFieldElement(
            countryCodes: countries
        ) { params, countryCode in
            // ...DropdownFieldElement should select the first and return the right country code
            XCTAssertEqual(countryCode, "NL")
            e.fulfill()
            return params
        }
        
        // ...DropdownFieldElement should display their localized names in alphabetical order
        XCTAssertEqual(country.items, ["Netherlands", "Spain"])
        
        _ = country.updateParams(params: IntentConfirmParams(type: .card))
        waitForExpectations(timeout: 1)
    }
}
