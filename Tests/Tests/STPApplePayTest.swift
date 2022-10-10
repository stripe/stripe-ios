//
//  STPApplePayTest.swift
//  StripeiOS
//
//  Created by David Estes on 9/21/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation
import XCTest
@testable @_spi(STP) import Stripe
@testable @_spi(STP) import StripeCore
@testable @_spi(STP) import StripePaymentSheet
@testable @_spi(STP) import StripePayments
@testable @_spi(STP) import StripePaymentsUI

class STPApplePaySwiftTest : XCTestCase {
    func testAdditionalPaymentNetwork() {
        XCTAssertFalse(StripeAPI.supportedPKPaymentNetworks().contains(.JCB))
        StripeAPI.additionalEnabledApplePayNetworks = [.JCB]
        XCTAssertTrue(StripeAPI.supportedPKPaymentNetworks().contains(.JCB))
        StripeAPI.additionalEnabledApplePayNetworks = []
    }
}
