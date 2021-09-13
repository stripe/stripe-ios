//
//  STPPostalCodeInputTextFieldTests.swift
//  StripeiOS Tests
//
//  Created by Ramon Torres on 9/3/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import XCTest

@testable import Stripe

class STPPostalCodeInputTextFieldTests: XCTestCase {

    func testClearingInvalidPostalCodeAfterCountryChange() {
        let postalCodeField = STPPostalCodeInputTextField()
        postalCodeField.countryCode = "UK"
        postalCodeField.text = "DL12" // valid UK post code, invalid US ZIP Code

        // Change country
        postalCodeField.countryCode = "US"

        XCTAssertEqual(postalCodeField.text, "",
            "Postal code field should clear its value if no longer valid after country change"
        )
    }

    func testPreservingValidPostalCodeAfterCountryChange() {
        let postalCodeField = STPPostalCodeInputTextField()
        postalCodeField.countryCode = "US"
        postalCodeField.text = "10010" // valid US and HR ZIP/postal code

        // Change country
        postalCodeField.countryCode = "HR"

        XCTAssertEqual(postalCodeField.text, "10010",
            "Postal code field should preserve its value if it is still valid after country change"
        )
    }
}
