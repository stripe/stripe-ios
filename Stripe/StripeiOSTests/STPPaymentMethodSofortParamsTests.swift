//  Converted to Swift 5.8.1 by Swiftify v5.8.28463 - https://swiftify.com/
//
//  STPPaymentMethodSofortParamsTests.m
//  StripeiOS Tests
//
//  Created by David Estes on 8/7/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import StripeCore
import StripeCoreTestUtils
import StripePaymentsTestUtils

class STPPaymentMethodSofortParamsTests: STPNetworkStubbingTestCase {
    func testCreateSofortPaymentMethod() {
        let client = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)
        let sofortParams = STPPaymentMethodSofortParams()
        sofortParams.country = "DE"
        let billingDetails = STPPaymentMethodBillingDetails()
        billingDetails.name = "Jenny Rosen"

        let params = STPPaymentMethodParams(
            sofort: sofortParams,
            billingDetails: billingDetails,
            metadata: [
                "test_key": "test_value"
            ])

        let expectation = self.expectation(description: "Payment Method Sofort create")

        client.createPaymentMethod(
            with: params) { paymentMethod, error in
            expectation.fulfill()

            XCTAssertNil(error, "Unexpected error creating Sofort PaymentMethod")
            XCTAssertNotNil(paymentMethod, "Failed to create Sofort PaymentMethod")
            XCTAssertNotNil(paymentMethod?.stripeId, "Missing stripeId")
            XCTAssertNotNil(paymentMethod?.created, "Missing created")
            XCTAssertFalse(paymentMethod!.liveMode, "Incorrect livemode")
                XCTAssertEqual(paymentMethod?.type, .sofort, "Incorrect PaymentMethod type")

            // Billing Details
            XCTAssertEqual(paymentMethod?.billingDetails!.name, "Jenny Rosen")

            // Sofort Details
            XCTAssertNotNil(paymentMethod?.sofort, "Missing Sofort")
            XCTAssertEqual(paymentMethod?.sofort!.country, "DE")
        }

        waitForExpectations(timeout: STPTestingNetworkRequestTimeout, handler: nil)
    }
}
