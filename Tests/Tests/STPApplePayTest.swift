//
//  STPApplePayTest.swift
//  StripeiOS
//
//  Created by David Estes on 9/21/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation
import XCTest
@testable import StripeCore
@testable import Stripe

class STPApplePaySwiftTest : XCTestCase {
    func testAdditionalPaymentNetwork() {
        XCTAssertFalse(StripeAPI.supportedPKPaymentNetworks().contains(.JCB))
        StripeAPI.additionalEnabledApplePayNetworks = [.JCB]
        XCTAssertTrue(StripeAPI.supportedPKPaymentNetworks().contains(.JCB))
        StripeAPI.additionalEnabledApplePayNetworks = []
    }
}
