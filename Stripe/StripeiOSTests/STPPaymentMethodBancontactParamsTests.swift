//  Converted to Swift 5.8.1 by Swiftify v5.8.28463 - https://swiftify.com/
//
//  STPPaymentMethodBancontactParamsTests.m
//  StripeiOS Tests
//
//  Created by Vineet Shah on 4/29/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import StripeCoreTestUtils
import StripePaymentsTestUtils

class STPPaymentMethodBancontactParamsTests: STPNetworkStubbingTestCase {
    func testCreateBancontactPaymentMethod() {
        let client = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)
        let bancontactParams = STPPaymentMethodBancontactParams()

        let billingDetails = STPPaymentMethodBillingDetails()
        billingDetails.name = "Jane Doe"

        let params = STPPaymentMethodParams(
            bancontact: bancontactParams,
            billingDetails: billingDetails,
            metadata: [
                "test_key": "test_value"
            ])

        let expectation = self.expectation(description: "Payment Method Bancontact create")

        client.createPaymentMethod(
            with: params) { paymentMethod, error in
            expectation.fulfill()

            XCTAssertNil(error, "Unexpected error creating Bancontact PaymentMethod")
            XCTAssertNotNil(paymentMethod, "Failed to create Bancontact PaymentMethod")
            XCTAssertNotNil(paymentMethod?.stripeId, "Missing stripeId")
            XCTAssertNotNil(paymentMethod?.created, "Missing created")
            XCTAssertFalse(paymentMethod!.liveMode, "Incorrect livemode")
                XCTAssertEqual(paymentMethod?.type, .bancontact, "Incorrect PaymentMethod type")

            // Billing Details
            XCTAssertEqual(paymentMethod?.billingDetails!.name, "Jane Doe")

            // Bancontact Details
            XCTAssertNotNil(paymentMethod?.bancontact, "Missing Bancontact")
        }

        waitForExpectations(timeout: STPTestingNetworkRequestTimeout, handler: nil)
    }
}
