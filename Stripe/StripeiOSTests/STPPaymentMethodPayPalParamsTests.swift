//  Converted to Swift 5.8.1 by Swiftify v5.8.28463 - https://swiftify.com/
//
//  STPPaymentMethodPayPalParamsTests.m
//  StripeiOS Tests
//
//  Created by Cameron Sabol on 10/7/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import StripeCoreTestUtils
import StripePaymentsTestUtils

class STPPaymentMethodPayPalParamsTests: STPNetworkStubbingTestCase {
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

            XCTAssertNil(error, "Unexpected error creating PayPal PaymentMethod")
            XCTAssertNotNil(paymentMethod, "Failed to create PayPal PaymentMethod")
            XCTAssertNotNil(paymentMethod?.stripeId, "Missing stripeId")
            XCTAssertNotNil(paymentMethod?.created, "Missing created")
            XCTAssertFalse(paymentMethod!.liveMode, "Incorrect livemode")
                XCTAssertEqual(paymentMethod?.type, .payPal, "Incorrect PaymentMethod type")

            // Billing Details
            XCTAssertEqual(paymentMethod?.billingDetails!.name, "Jane Doe")

            // PayPal Details
            XCTAssertNotNil(paymentMethod?.payPal, "Missing PayPal")
        }

        waitForExpectations(timeout: STPTestingNetworkRequestTimeout, handler: nil)
    }
}
