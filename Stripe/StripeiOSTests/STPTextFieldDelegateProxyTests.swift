//
//  STPTextFieldDelegateProxyTests.swift
//  StripeiOS Tests
//
//  Created by Ramon Torres on 11/29/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import XCTest

@testable@_spi(STP) import Stripe
@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePayments
@testable@_spi(STP) import StripePaymentSheet
@testable@_spi(STP) import StripePaymentsUI

class STPTextFieldDelegateProxyTests: XCTestCase {

    func testProxyShouldDeleteLeadingWhitespace() {
        let textField = STPFormTextField()
        textField.autoFormattingBehavior = .cardNumbers
        textField.text = " "  // space

        let sut = STPTextFieldDelegateProxy()

        let result = sut.textField(
            textField,
            shouldChangeCharactersIn: NSRange(location: 0, length: 1),
            replacementString: ""
        )

        // Proxy should handle the deletion and return `false`.
        XCTAssertFalse(result)
        XCTAssertEqual(textField.text, "")
    }

}
