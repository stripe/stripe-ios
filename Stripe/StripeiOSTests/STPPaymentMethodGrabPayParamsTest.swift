//  Converted to Swift 5.8.1 by Swiftify v5.8.28463 - https://swiftify.com/
//
//  STPPaymentMethodGrabPayParamsTest.m
//  StripeiOS Tests
//
//  Created by Yuki Tokuhiro on 7/21/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import StripeCore
import StripeCoreTestUtils
import StripePaymentsTestUtils

class STPPaymentMethodGrabPayParamsTest: STPNetworkStubbingTestCase {
    func testCreateGrabPayPaymentMethod() {
        let client = STPAPIClient(publishableKey: STPTestingSGPublishableKey)
        let grabPayParams = STPPaymentMethodGrabPayParams()

        let billingDetails = STPPaymentMethodBillingDetails()
        billingDetails.name = "Jenny Rosen"

        let params = STPPaymentMethodParams(
            grabPay: grabPayParams,
            billingDetails: billingDetails,
            metadata: [
                "test_key": "test_value"
            ])

        let expectation = self.expectation(description: "Payment Method GrabPay create")

        client.createPaymentMethod(
            with: params) { paymentMethod, error in
            expectation.fulfill()

            XCTAssertNil(error, "Unexpected error creating GrabPay PaymentMethod")
            XCTAssertNotNil(paymentMethod, "Failed to create GrabPay PaymentMethod")
            XCTAssertNotNil(paymentMethod?.stripeId, "Missing stripeId")
            XCTAssertNotNil(paymentMethod?.created, "Missing created")
            XCTAssertFalse(paymentMethod!.liveMode, "Incorrect livemode")
                XCTAssertEqual(paymentMethod?.type, .grabPay, "Incorrect PaymentMethod type")

            // Billing Details
            XCTAssertEqual(paymentMethod?.billingDetails!.name, "Jenny Rosen")

            // GrabPay Details
            XCTAssertNotNil(paymentMethod?.grabPay, "Missing grabPay")
        }

        waitForExpectations(timeout: STPTestingNetworkRequestTimeout, handler: nil)
    }
}
