//
//  STPPaymentCardTextFieldTestsSwift.swift
//  StripeiOS Tests
//
//  Created by Cameron Sabol on 8/24/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import XCTest

@testable import Stripe

class STPPaymentCardTextFieldTestsSwift: XCTestCase {

    func testClearMaintainsPostalCodeEntryEnabled() {
        let textField = STPPaymentCardTextField()
        let postalCodeEntryDefaultEnabled = textField.postalCodeEntryEnabled
        textField.clear()
        XCTAssertEqual(postalCodeEntryDefaultEnabled, textField.postalCodeEntryEnabled, "clear overrode default postalCodeEntryEnabled value")
        
        // --
        textField.postalCodeEntryEnabled = false
        textField.clear()
        XCTAssertFalse(textField.postalCodeEntryEnabled, "clear overrode custom postalCodeEntryEnabled false value")
        
        // --
        textField.postalCodeEntryEnabled = true
        // The ORs in this test are to handle if these tests are run in an environment
        // where the locale doesn't require postal codes, in which case the calculated
        // value for postalCodeEntryEnabled can be different than the value set
        // (this is a legacy API).
        let stillTrueOrRequestedButNoPostal = textField.postalCodeEntryEnabled ||
            (textField.viewModel.postalCodeRequested && STPPostalCodeValidator.postalCodeIsRequired(forCountryCode: textField.viewModel.postalCodeCountryCode))
        XCTAssertTrue(stillTrueOrRequestedButNoPostal, "clear overrode custom postalCodeEntryEnabled true value")
        
    }

    func testPostalCodeIsValidWhenExpirationIsNot() {
        let cardTextField = STPPaymentCardTextField()

        // Old expiration date
        cardTextField.expirationField.text = "10/10"
        XCTAssertFalse(cardTextField.expirationField.validText)

        cardTextField.postalCode = "10001"
        cardTextField.formTextFieldTextDidChange(cardTextField.postalCodeField)
        XCTAssertTrue(cardTextField.postalCodeField.validText)
    }
}
