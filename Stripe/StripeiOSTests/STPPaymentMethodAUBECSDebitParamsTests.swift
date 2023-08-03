//  Converted to Swift 5.8.1 by Swiftify v5.8.28463 - https://swiftify.com/
//
//  STPPaymentMethodAUBECSDebitParamsTests.swift
//  StripeiOS Tests
//
//  Created by Cameron Sabol on 3/4/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import StripeCoreTestUtils

class STPPaymentMethodAUBECSDebitParamsTests: XCTestCase {
    func testCreateAUBECSPaymentMethod() {
        let client = STPAPIClient(publishableKey: STPTestingAUPublishableKey)
        let becsParams = STPPaymentMethodAUBECSDebitParams()
        becsParams.bsbNumber = "000000" // Stripe test bank
        becsParams.accountNumber = "000123456" // test account

        let billingDetails = STPPaymentMethodBillingDetails()
        billingDetails.name = "Jenny Rosen"
        billingDetails.email = "jrosen@example.com"

        let params = STPPaymentMethodParams(
            aubecsDebit: becsParams,
            billingDetails: billingDetails,
            metadata: [
                "test_key": "test_value"
            ])

        let expectation = self.expectation(description: "Payment Method AU BECS Debit create")

        client.createPaymentMethod(
            with: params) { paymentMethod, error in
            expectation.fulfill()

            XCTAssertNil(error)
            XCTAssertNotNil(Int(paymentMethod ?? 0))
            XCTAssertNotNil(paymentMethod?.stripeId ?? 0)
            XCTAssertNotNil(paymentMethod?.created ?? 0)
            XCTAssertFalse(paymentMethod?.liveMode, "Incorrect livemode")
            XCTAssertEqual(paymentMethod?.type ?? 0, Int(STPPaymentMethodTypeAUBECSDebit))

            // Billing Details
            XCTAssertEqual(paymentMethod?.billingDetails.email, "jrosen@example.com")
            XCTAssertEqual(paymentMethod?.billingDetails.name, "Jenny Rosen")

            // AU BECS Debit
            XCTAssertEqual(paymentMethod?.auBECSDebit.bsbNumber, "000000")
            XCTAssertEqual(paymentMethod?.auBECSDebit.last4, "3456")
            XCTAssertNotNil(paymentMethod?.auBECSDebit.fingerprint ?? 0)
        }

        waitForExpectations(timeout: TestConstants.stpTestingNetworkRequestTimeout, handler: nil)
    }
}