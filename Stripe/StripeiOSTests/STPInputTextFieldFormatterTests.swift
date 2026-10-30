//
//  STPInputTextFieldFormatterTests.swift
//  StripeiOS Tests
//
//  Created by Cameron Sabol on 10/28/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import UIKit
import XCTest

@testable@_spi(InternalOnlyAPI) import Stripe
@testable@_spi(InternalOnlyAPI) import StripeCore
@testable@_spi(InternalOnlyAPI) import StripePayments
@testable@_spi(InternalOnlyAPI) import StripePaymentSheet
@testable@_spi(InternalOnlyAPI) import StripePaymentsUI

class STPInputTextFieldFormatterTests: XCTestCase {

    func testAllowsDeletion() {
        let formatter = STPInputTextFieldFormatter()
        let textField = UITextField()
        XCTAssertTrue(
            formatter.textField(
                textField,
                shouldChangeCharactersIn: NSRange(location: 0, length: 2),
                replacementString: ""
            ),
            "Should allow deletion on empty"
        )
        textField.text = "Hi"
        XCTAssertTrue(
            formatter.textField(
                textField,
                shouldChangeCharactersIn: NSRange(location: 0, length: 2),
                replacementString: ""
            ),
            "Should allow full deletion"
        )
        textField.text = "Hello"
        XCTAssertTrue(
            formatter.textField(
                textField,
                shouldChangeCharactersIn: NSRange(location: 4, length: 1),
                replacementString: ""
            ),
            "Should allow partial deletion at end"
        )
        textField.text = "Hello"
        XCTAssertTrue(
            formatter.textField(
                textField,
                shouldChangeCharactersIn: NSRange(location: 3, length: 1),
                replacementString: ""
            ),
            "Should allow partial deletion in middle"
        )
        textField.text = "Hello"
        XCTAssertTrue(
            formatter.textField(
                textField,
                shouldChangeCharactersIn: NSRange(location: 0, length: 1),
                replacementString: ""
            ),
            "Should allow partial deletion at beginning"
        )
    }

    func testAllowsInitialSpaceForAutofill() {
        let formatter = STPInputTextFieldFormatter()
        let textField = UITextField()
        textField.textContentType = .nickname
        XCTAssertTrue(
            formatter.textField(
                textField,
                shouldChangeCharactersIn: NSRange(location: 0, length: 0),
                replacementString: " "
            )
        )
    }

}
