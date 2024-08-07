//  Converted to Swift 5.8.1 by Swiftify v5.8.28463 - https://swiftify.com/
//
//  STPPaymentMethodGiropayParamsTests.m
//  StripeiOS Tests
//
//  Created by Cameron Sabol on 4/21/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import StripeCoreTestUtils
import StripePaymentsTestUtils

class STPPaymentMethodGiropayParamsTests: STPNetworkStubbingTestCase {
    func testCreateGiropayPaymentMethod() {
        let client = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)
        let giropayParams = STPPaymentMethodGiropayParams()

        let billingDetails = STPPaymentMethodBillingDetails()
        billingDetails.name = "Jenny Rosen"

        let params = STPPaymentMethodParams(
            giropay: giropayParams,
            billingDetails: billingDetails,
            metadata: [
                "test_key": "test_value"
            ])

        let expectation = self.expectation(description: "Payment Method giropay create")

        client.createPaymentMethod(
            with: params) { paymentMethod, error in
            expectation.fulfill()

            XCTAssertNil(error, "Unexpected error creating giropay PaymentMethod")
            XCTAssertNotNil(paymentMethod, "Failed to create giropay PaymentMethod")
            XCTAssertNotNil(paymentMethod?.stripeId, "Missing stripeId")
            XCTAssertNotNil(paymentMethod?.created, "Missing created")
            XCTAssertFalse(paymentMethod!.liveMode, "Incorrect livemode")
                XCTAssertEqual(paymentMethod?.type, .giropay, "Incorrect PaymentMethod type")

            // Billing Details
            XCTAssertEqual(paymentMethod?.billingDetails!.name, "Jenny Rosen")

            // giropay Details
            XCTAssertNotNil(paymentMethod?.giropay, "Missing giropay")
        }

        waitForExpectations(timeout: STPTestingNetworkRequestTimeout, handler: nil)
    }
}
