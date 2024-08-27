//  Converted to Swift 5.8.1 by Swiftify v5.8.28463 - https://swiftify.com/
//
//  STPPaymentMethodAfterpayClearpayParamsTest.m
//  StripeiOS Tests
//
//  Created by Ali Riaz on 1/14/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import StripeCoreTestUtils
import StripePaymentsTestUtils

class STPPaymentMethodAfterpayClearpayParamsTest: STPNetworkStubbingTestCase {
    func testCreateAfterpayClearpayPaymentMethod() {
        let client = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)
        let afterpayClearpayParams = STPPaymentMethodAfterpayClearpayParams()

        let billingDetails = STPPaymentMethodBillingDetails()
        billingDetails.name = "Jenny Rosen"
        billingDetails.email = "jrosen@example.com"
        billingDetails.address = STPPaymentMethodAddress()
        billingDetails.address!.line1 = "510 Townsend St."
        billingDetails.address!.postalCode = "94102"
        billingDetails.address!.country = "US"

        let params = STPPaymentMethodParams(
            afterpayClearpay: afterpayClearpayParams,
            billingDetails: billingDetails,
            metadata: [
                "test_key": "test_value"
            ])

        let expectation = self.expectation(description: "Payment Method AfterpayClearpay create")

        client.createPaymentMethod(with: params) { paymentMethod, error in
            expectation.fulfill()

            XCTAssertNil(error, "Unexpected error creating AfterpayClearpay Payment Method")
            XCTAssertNotNil(paymentMethod, "Failed to create AfterpayClearpay PaymentMethod")
            XCTAssertNotNil(paymentMethod?.stripeId, "Missing stripeId")
            XCTAssertNotNil(paymentMethod?.created, "Missing created")
            XCTAssertFalse(paymentMethod!.liveMode, "Incorrect livemode")
            XCTAssertEqual(paymentMethod?.type, .afterpayClearpay, "Incorrect PaymentMethod type")
            XCTAssertNil(paymentMethod?.perform(NSSelectorFromString("metadata")), "Metadata is not returned.")

            // Billing Details
            XCTAssertEqual(paymentMethod?.billingDetails!.email, "jrosen@example.com")
            XCTAssertEqual(paymentMethod?.billingDetails!.name, "Jenny Rosen")
            XCTAssertEqual(paymentMethod?.billingDetails!.address!.line1, "510 Townsend St.")
            XCTAssertEqual(paymentMethod?.billingDetails!.address!.postalCode, "94102")
            XCTAssertEqual(paymentMethod?.billingDetails!.address!.country, "US")

            XCTAssertNotNil(paymentMethod?.afterpayClearpay, "")
        }

        waitForExpectations(timeout: STPTestingNetworkRequestTimeout, handler: nil)

    }
}
