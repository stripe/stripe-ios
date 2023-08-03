//  Converted to Swift 5.8.1 by Swiftify v5.8.28463 - https://swiftify.com/
import Foundation
import XCTest

@testable@_spi(STP) import Stripe
@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePayments
@testable@_spi(STP) import StripePaymentSheet
@testable@_spi(STP) import StripePaymentsUI
//
//  STPPaymentMethodPrzelewy24ParamsTests.swift
//  StripeiOS Tests
//
//  Created by Vineet Shah on 4/23/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import StripeCore
import StripeCoreTestUtils

class STPPaymentMethodPrzelewy24ParamsTests: XCTestCase {
    func testCreatePrzelewy24PaymentMethod() {
        let client = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)
        let przelewy24Params = STPPaymentMethodPrzelewy24Params()

        let billingDetails = STPPaymentMethodBillingDetails()
        billingDetails.email = "email@email.com"

        let params = STPPaymentMethodParams(
            przelewy24: przelewy24Params,
            billingDetails: billingDetails,
            metadata: [
                "test_key": "test_value"
            ])

        let expectation = self.expectation(description: "Payment Method Przelewy24 create")

        client.createPaymentMethod(
            with: params) { paymentMethod, error in
            expectation.fulfill()

            XCTAssertNil(error)
            XCTAssertNotNil(Int(paymentMethod ?? 0))
            XCTAssertNotNil(paymentMethod?.stripeId ?? 0)
            XCTAssertNotNil(paymentMethod?.created ?? 0)
            XCTAssertFalse(paymentMethod?.liveMode, "Incorrect livemode")
            XCTAssertEqual(paymentMethod?.type ?? 0, Int(STPPaymentMethodTypePrzelewy24))

            // Billing Details
            XCTAssertEqual(paymentMethod?.billingDetails.email, "email@email.com")

            // Przelewy24 Details
            XCTAssertNotNil(paymentMethod?.przelewy24 ?? 0)
        }

        waitForExpectations(timeout: TestConstants.stpTestingNetworkRequestTimeout, handler: nil)
    }
}
