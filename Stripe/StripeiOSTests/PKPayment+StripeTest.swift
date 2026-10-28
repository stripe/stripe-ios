//
//  PKPayment+StripeTest.swift
//  StripeiOS Tests
//
//  Created by Ben Guo on 7/6/15.
//  Copyright © 2015 Stripe, Inc. All rights reserved.
//

import PassKit
import XCTest

@testable@_spi(InternalOnlyAPI) import Stripe
@testable@_spi(InternalOnlyAPI) import StripeCore
@testable@_spi(InternalOnlyAPI) import StripePayments
@testable@_spi(InternalOnlyAPI) import StripePaymentSheet
@testable@_spi(InternalOnlyAPI) import StripePaymentsUI

class PKPayment_StripeTest: XCTestCase {
    func testIsSimulated() {
        let payment = PKPayment()
        let paymentToken = PKPaymentToken()

        // #pragma clang diagnostic push
        // #pragma clang diagnostic ignored "-Wundeclared-selector"
        paymentToken.perform(Selector(("setTransactionIdentifier:")), with: "Simulated Identifier")
        payment.perform(#selector(setter: STPPaymentMethodCardParams.token), with: paymentToken)
        // #pragma clang diagnostic pop

        XCTAssertTrue(payment.stp_isSimulated())
    }

    func testTransactionIdentifier() {
        let identifier = PKPayment.stp_testTransactionIdentifier()
        XCTAssertTrue(identifier.contains("ApplePayStubs~4242424242424242~0~USD~"))
    }
}
