//  Converted to Swift 5.8.1 by Swiftify v5.8.28463 - https://swiftify.com/
//
//  STPPaymentMethodUPIParamsTest.m
//  StripeiOS Tests
//
//  Created by Anirudh Bhargava on 11/6/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import StripeCore
import StripeCoreTestUtils
import StripePaymentsTestUtils

class STPPaymentMethodUPIParamsTests: STPNetworkStubbingTestCase {
    func testCreateUPIPaymentMethod() {
        let client = STPAPIClient(publishableKey: STPTestingINPublishableKey)
        let upiParams = STPPaymentMethodUPIParams()
        upiParams.vpa = "somevpa@hdfcbank"
        let billingDetails = STPPaymentMethodBillingDetails()
        billingDetails.name = "Jenny Rosen"

        let params = STPPaymentMethodParams(
            upi: upiParams,
            billingDetails: billingDetails,
            metadata: [
                "test_key": "test_value"
            ])

        let expectation = self.expectation(description: "Payment Method UPI create")

        client.createPaymentMethod(
            with: params) { paymentMethod, error in
            expectation.fulfill()

            XCTAssertNil(error, "Unexpected error creating UPI PaymentMethod")
            XCTAssertNotNil(paymentMethod, "Failed to create UPI PaymentMethod")
            XCTAssertNotNil(paymentMethod?.stripeId, "Missing stripeId")
            XCTAssertNotNil(paymentMethod?.created, "Missing created")
            XCTAssertFalse(paymentMethod!.liveMode, "Incorrect livemode")
                XCTAssertEqual(paymentMethod?.type, .UPI, "Incorrect PaymentMethod type")

            // Billing Details
            XCTAssertEqual(paymentMethod?.billingDetails!.name, "Jenny Rosen")

            // UPI Details
            XCTAssertNotNil(paymentMethod?.upi, "Missing UPI")
            XCTAssertEqual(paymentMethod?.upi!.vpa, "somevpa@hdfcbank")
        }

        waitForExpectations(timeout: STPTestingNetworkRequestTimeout, handler: nil)
    }
}
