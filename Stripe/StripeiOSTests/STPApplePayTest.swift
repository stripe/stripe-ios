//
//  STPApplePayTest.swift
//  StripeiOS Tests
//
//  Created by David Estes on 9/21/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation
import XCTest

@testable@_spi(STP) import Stripe
@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePayments
@testable@_spi(STP) import StripePaymentSheet
@testable@_spi(STP) import StripePaymentsUI

class STPApplePaySwiftTest: XCTestCase {
    func testAdditionalPaymentNetwork() {
        XCTAssertFalse(StripeAPI.supportedPKPaymentNetworks().contains(.JCB))
        StripeAPI.additionalEnabledApplePayNetworks = [.JCB]
        XCTAssertTrue(StripeAPI.supportedPKPaymentNetworks().contains(.JCB))
        StripeAPI.additionalEnabledApplePayNetworks = []
    }

    // Tests stp_tokenParameters in StripePayments, not StripeApplePay
    func testStpTokenParameters() {
        let applePay = STPFixtures.applePayPayment()
        let applePayDict = applePay.stp_tokenParameters(apiClient: .shared)
        XCTAssertNotNil(applePayDict["pk_token"])
        XCTAssertEqual((applePayDict["card"] as! NSDictionary)["name"] as! String, "Test Testerson")
        XCTAssertEqual(applePayDict["pk_token_instrument_name"] as! String, "Master Charge")
    }
}
