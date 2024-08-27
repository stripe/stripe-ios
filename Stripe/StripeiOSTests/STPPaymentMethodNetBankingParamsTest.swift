//  Converted to Swift 5.8.1 by Swiftify v5.8.28463 - https://swiftify.com/
//
//  STPPaymentMethodNetBankingParamsTest.m
//  StripeiOS
//
//  Created by Anirudh Bhargava on 11/19/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import StripeCore
import StripeCoreTestUtils
import StripePaymentsTestUtils

class STPPaymentMethodNetBankingParamsTests: STPNetworkStubbingTestCase {
    func testCreateNetBankingPaymentMethod() {
        let client = STPAPIClient(publishableKey: STPTestingINPublishableKey)
        let netbankingParams = STPPaymentMethodNetBankingParams()
        netbankingParams.bank = "icici"
        let billingDetails = STPPaymentMethodBillingDetails()
        billingDetails.name = "Jenny Rosen"

        let params = STPPaymentMethodParams(
            netBanking: netbankingParams,
            billingDetails: billingDetails,
            metadata: [
                "test_key": "test_value"
            ])

        let expectation = self.expectation(description: "Payment Method NetBanking create")
        client.createPaymentMethod(
            with: params) { paymentMethod, error in
            expectation.fulfill()
            XCTAssertNil(error, "Unexpected error creating NetBanking PaymentMethod")
            XCTAssertNotNil(paymentMethod, "Failed to create NetBanking PaymentMethod")
            XCTAssertNotNil(paymentMethod?.stripeId, "Missing stripeId")
            XCTAssertNotNil(paymentMethod?.created, "Missing created")
            XCTAssertFalse(paymentMethod!.liveMode, "Incorrect livemode")
                XCTAssertEqual(paymentMethod?.type, .netBanking, "Incorrect PaymentMethod type")
            // Billing Details
            XCTAssertEqual(paymentMethod?.billingDetails!.name, "Jenny Rosen")
            // UPI Details
            XCTAssertNotNil(paymentMethod?.netBanking, "Missing NetBanking")
            XCTAssertEqual(paymentMethod?.netBanking!.bank, "icici")
        }
        waitForExpectations(timeout: STPTestingNetworkRequestTimeout, handler: nil)
    }
}
