//
//  STPCardCVCInputTextFieldTests.swift
//  StripeiOS Tests
//
//  Created by Ramon Torres on 8/31/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import XCTest

@testable@_spi(STP) import Stripe
@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePayments
@testable@_spi(STP) import StripePaymentSheet
@testable@_spi(STP) import StripePaymentsUI

class STPCardCVCInputTextFieldTests: XCTestCase {

    func testTruncatingCVCWhenTooLong() {
        let cvcField = STPCardCVCInputTextField()
        cvcField.cardBrand = .amex
        cvcField.text = String(
            repeating: "1",
            count: Int(STPCardValidator.maxCVCLength(for: .amex))
        )
        XCTAssertEqual(cvcField.text?.count, Int(STPCardValidator.maxCVCLength(for: .amex)))

        // Switching the card brand to `visa` should truncate the field text to
        // the max length allowed for the brand
        cvcField.cardBrand = .visa
        XCTAssertEqual(cvcField.text?.count, Int(STPCardValidator.maxCVCLength(for: .visa)))
    }

}
