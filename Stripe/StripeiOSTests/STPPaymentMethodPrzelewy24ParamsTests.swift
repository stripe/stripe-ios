//  Converted to Swift 5.8.1 by Swiftify v5.8.28463 - https://swiftify.com/
//
//  STPPaymentMethodPrzelewy24ParamsTests.m
//  StripeiOS Tests
//
//  Created by Vineet Shah on 4/23/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import StripeCore
import StripeCoreTestUtils
import StripePaymentsTestUtils

class STPPaymentMethodPrzelewy24ParamsTests: STPNetworkStubbingTestCase {
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

            XCTAssertNil(error, "Unexpected error creating Przelewy24 PaymentMethod")
            XCTAssertNotNil(paymentMethod, "Failed to create Przelewy24 PaymentMethod")
            XCTAssertNotNil(paymentMethod?.stripeId, "Missing stripeId")
            XCTAssertNotNil(paymentMethod?.created, "Missing created")
            XCTAssertFalse(paymentMethod!.liveMode, "Incorrect livemode")
                XCTAssertEqual(paymentMethod?.type, .przelewy24, "Incorrect PaymentMethod type")

            // Billing Details
            XCTAssertEqual(paymentMethod?.billingDetails!.email, "email@email.com")

            // Przelewy24 Details
            XCTAssertNotNil(paymentMethod?.przelewy24, "Missing Przelewy24")
        }

        waitForExpectations(timeout: STPTestingNetworkRequestTimeout, handler: nil)
    }
}
