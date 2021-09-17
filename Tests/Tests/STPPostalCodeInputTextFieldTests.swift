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
        let postalCodeField = STPPostalCodeInputTextField(postalCodeRequirement: .standard)
        postalCodeField.countryCode = "UK"
        postalCodeField.text = "DL12" // valid UK post code, invalid US ZIP Code

        // Change country
        postalCodeField.countryCode = "US"

        XCTAssertEqual(postalCodeField.text, "",
            "Postal code field should clear its value if no longer valid after country change"
        )
    }

    func testPreservingValidPostalCodeAfterCountryChange() {
        let postalCodeField = STPPostalCodeInputTextField(postalCodeRequirement: .standard)
        postalCodeField.countryCode = "US"
        postalCodeField.text = "10010" // valid US and HR ZIP/postal code

        // Change country
        postalCodeField.countryCode = "HR"

        XCTAssertEqual(postalCodeField.text, "10010",
            "Postal code field should preserve its value if it is still valid after country change"
        )
    }
    
    func testChangeToNonRequiredPostalCodeIsValid() {
        let postalCodeField = STPPostalCodeInputTextField(postalCodeRequirement: .upe)
        // given that the postal code field is empty...
        
        // when
        postalCodeField.countryCode = "US"
        if case .incomplete = postalCodeField.validationState {
            // pass
        } else {
            XCTFail("Empty postal code should be incomplete for US")
        }
        
        // when
        postalCodeField.countryCode = "FR"
        if case .valid = postalCodeField.validationState {
            // pass
        } else {
            XCTFail("Empty postal code should be valid for non-required country")
        }
    }
}
