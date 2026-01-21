//
//  STPPaymentMethodTwintParamsTests.swift
//  StripeiOS Tests
//
//  Copyright © 2024 Stripe, Inc. All rights reserved.
//

import StripeCoreTestUtils
import StripePaymentsTestUtils

class STPPaymentMethodTwintParamsTests: STPNetworkStubbingTestCase {
    func testCreateTwintPaymentMethod() {
        let client = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)
        let twintParams = STPPaymentMethodTwintParams()

        let billingDetails = STPPaymentMethodBillingDetails()
        billingDetails.name = "Jane Doe"

        let params = STPPaymentMethodParams(
            twint: twintParams,
            billingDetails: billingDetails,
            metadata: [
                "test_key": "test_value"
            ])

        let expectation = self.expectation(description: "Payment Method TWINT create")

        client.createPaymentMethod(
            with: params) { paymentMethod, error in
            expectation.fulfill()

            XCTAssertNil(error, "Unexpected error creating TWINT PaymentMethod")
            XCTAssertNotNil(paymentMethod, "Failed to create TWINT PaymentMethod")
            XCTAssertNotNil(paymentMethod?.stripeId, "Missing stripeId")
            XCTAssertNotNil(paymentMethod?.created, "Missing created")
            XCTAssertFalse(paymentMethod!.liveMode, "Incorrect livemode")
            XCTAssertEqual(paymentMethod?.type, .twint, "Incorrect PaymentMethod type")

            // Billing Details
            XCTAssertEqual(paymentMethod?.billingDetails!.name, "Jane Doe")

            // TWINT Details
            XCTAssertNotNil(paymentMethod?.twint, "Missing TWINT")
        }

        waitForExpectations(timeout: STPTestingNetworkRequestTimeout, handler: nil)
    }
}
