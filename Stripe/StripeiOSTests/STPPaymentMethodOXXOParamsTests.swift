//  Converted to Swift 5.8.1 by Swiftify v5.8.28463 - https://swiftify.com/
//
//  STPPaymentMethodOXXOParamsTests.m
//  StripeiOS Tests
//
//  Created by Polo Li on 6/16/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import StripeCore
import StripeCoreTestUtils
import StripePaymentsTestUtils

class STPPaymentMethodOXXOParamsTests: STPNetworkStubbingTestCase {
    func testCreateOXXOPaymentMethod() {
        let client = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)
        let oxxoParams = STPPaymentMethodOXXOParams()

        let billingDetails = STPPaymentMethodBillingDetails()
        billingDetails.name = "Jane Doe"
        billingDetails.email = "test@test.com"

        let params = STPPaymentMethodParams(
            oxxo: oxxoParams,
            billingDetails: billingDetails,
            metadata: [
                "test_key": "test_value"
            ])

        let expectation = self.expectation(description: "Payment Method OXXO create")

        client.createPaymentMethod(
            with: params) { paymentMethod, error in
            expectation.fulfill()

            XCTAssertNil(error, "Unexpected error creating OXXO PaymentMethod")
            XCTAssertNotNil(paymentMethod, "Failed to create OXXO PaymentMethod")
            XCTAssertNotNil(paymentMethod?.stripeId, "Missing stripeId")
            XCTAssertNotNil(paymentMethod?.created, "Missing created")
            XCTAssertFalse(paymentMethod!.liveMode, "Incorrect livemode")
            XCTAssertEqual(paymentMethod?.type, .OXXO, "Incorrect PaymentMethod type")

            // Billing Details
                XCTAssertEqual(paymentMethod?.billingDetails?.name, "Jane Doe")
            XCTAssertEqual(paymentMethod?.billingDetails?.email, "test@test.com")

            // OXXO Details
            XCTAssertNotNil(paymentMethod?.oxxo, "Missing OXXO")
        }

        waitForExpectations(timeout: STPTestingNetworkRequestTimeout, handler: nil)
    }
}
