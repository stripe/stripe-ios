//  Converted to Swift 5.8.1 by Swiftify v5.8.28463 - https://swiftify.com/
//
//  STPPaymentMethodEPSParamsTests.m
//  StripeiOS Tests
//
//  Created by Shengwei Wu on 5/15/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import StripeCore
import StripeCoreTestUtils
import StripePaymentsTestUtils

class STPPaymentMethodEPSParamsTests: STPNetworkStubbingTestCase {
    func testCreateEPSPaymentMethod() {
        let client = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)
        let epsParams = STPPaymentMethodEPSParams()

        let billingDetails = STPPaymentMethodBillingDetails()
        billingDetails.name = "Jenny Rosen"

        let params = STPPaymentMethodParams(
            eps: epsParams,
            billingDetails: billingDetails,
            metadata: [
                "test_key": "test_value"
            ])

        let expectation = self.expectation(description: "Payment Method EPS create")

        client.createPaymentMethod(
            with: params) { paymentMethod, error in
            expectation.fulfill()

            XCTAssertNil(error, "Unexpected error creating EPS PaymentMethod")
            XCTAssertNotNil(paymentMethod, "Failed to create EPS PaymentMethod")
            XCTAssertNotNil(paymentMethod?.stripeId, "Missing stripeId")
            XCTAssertNotNil(paymentMethod?.created, "Missing created")
            XCTAssertFalse(paymentMethod!.liveMode, "Incorrect livemode")
                XCTAssertEqual(paymentMethod?.type, .EPS, "Incorrect PaymentMethod type")

            // Billing Details
                XCTAssertEqual(paymentMethod?.billingDetails!.name, "Jenny Rosen")

            // EPS Details
            XCTAssertNotNil(paymentMethod?.eps, "Missing eps")
        }

        waitForExpectations(timeout: STPTestingNetworkRequestTimeout, handler: nil)
    }
}
