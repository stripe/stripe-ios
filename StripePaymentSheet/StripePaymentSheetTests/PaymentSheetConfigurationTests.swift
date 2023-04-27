//
//  PaymentSheetConfigurationTests.swift
//  StripePaymentSheetTests
//
//  Copyright © 2023 Stripe, Inc. All rights reserved.
//

import CwlPreconditionTesting
import StripePaymentSheet
import XCTest

final class PaymentSheetConfigurationTests: XCTestCase {

    func test_customerConfigurationInit_assertsWhenEphemeralKeyIsBlank() {
        let exception = catchBadInstruction {
            _ = PaymentSheet.CustomerConfiguration(id: "foo", ephemeralKeySecret: "")
        }

        XCTAssertNotNil(exception)
    }
}
