//  Converted to Swift 5.8.1 by Swiftify v5.8.28463 - https://swiftify.com/
import Foundation
import XCTest

@testable@_spi(STP) import Stripe
@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePayments
@testable@_spi(STP) import StripePaymentSheet
@testable@_spi(STP) import StripePaymentsUI
//
//  STPPaymentMethodPayPalParamsTests.swift
//  StripeiOS Tests
//
//  Created by Cameron Sabol on 10/7/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import StripeCoreTestUtils

class STPPaymentMethodPayPalParamsTests: XCTestCase {
    func testCreatePayPalPaymentMethod() {
        let client = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)
        let payPalParams = STPPaymentMethodPayPalParams()

        let billingDetails = STPPaymentMethodBillingDetails()
        billingDetails.name = "Jane Doe"

        let params = STPPaymentMethodParams(
            payPal: payPalParams,
            billingDetails: billingDetails,
            metadata: [
                "test_key": "test_value"
            ])

        let expectation = self.expectation(description: "Payment Method PayPal create")

        client.createPaymentMethod(
            with: params) { paymentMethod, error in
            expectation.fulfill()

            XCTAssertNil(error)
            XCTAssertNotNil(Int(paymentMethod ?? 0))
            XCTAssertNotNil(paymentMethod?.stripeId ?? 0)
            XCTAssertNotNil(paymentMethod?.created ?? 0)
            XCTAssertFalse(paymentMethod?.liveMode, "Incorrect livemode")
            XCTAssertEqual(paymentMethod?.type ?? 0, Int(STPPaymentMethodTypePayPal))

            // Billing Details
            XCTAssertEqual(paymentMethod?.billingDetails.name, "Jane Doe")

            // PayPal Details
            XCTAssertNotNil(paymentMethod?.payPal ?? 0)
        }

        waitForExpectations(timeout: TestConstants.stpTestingNetworkRequestTimeout, handler: nil)
    }
}
