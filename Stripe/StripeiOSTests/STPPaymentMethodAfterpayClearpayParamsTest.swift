//  Converted to Swift 5.8.1 by Swiftify v5.8.28463 - https://swiftify.com/
import Foundation
import XCTest

@testable@_spi(STP) import Stripe
@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePayments
@testable@_spi(STP) import StripePaymentSheet
@testable@_spi(STP) import StripePaymentsUI
//
//  STPPaymentMethodAfterpayClearpayParamsTest.swift
//  StripeiOS Tests
//
//  Created by Ali Riaz on 1/14/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import StripeCoreTestUtils

class STPPaymentMethodAfterpayClearpayParamsTest: XCTestCase {
    func testCreateAfterpayClearpayPaymentMethod() {
        let client = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)
        let afterpayClearpayParams = STPPaymentMethodAfterpayClearpayParams()

        let billingDetails = STPPaymentMethodBillingDetails()
        billingDetails.name = "Jenny Rosen"
        billingDetails.email = "jrosen@example.com"
        billingDetails.address = STPPaymentMethodAddress()
        billingDetails.address.line1 = "510 Townsend St."
        billingDetails.address.postalCode = "94102"
        billingDetails.address.country = "US"

        let params = STPPaymentMethodParams(
            afterpayClearpay: afterpayClearpayParams,
            billingDetails: billingDetails,
            metadata: [
                "test_key": "test_value"
            ])

        let expectation = self.expectation(description: "Payment Method AfterpayClearpay create")

        client.createPaymentMethod(with: params) { paymentMethod, error in
            expectation.fulfill()

            XCTAssertNil(error)
            XCTAssertNotNil(Int(paymentMethod ?? 0))
            XCTAssertNotNil(paymentMethod?.stripeId ?? 0)
            XCTAssertNotNil(paymentMethod?.created ?? 0)
            XCTAssertFalse(paymentMethod?.liveMode, "Incorrect livemode")
            XCTAssertEqual(paymentMethod?.type ?? 0, Int(STPPaymentMethodTypeAfterpayClearpay))
            //#pragma clang diagnostic push
            //#pragma clang diagnostic ignored "-Wdeprecated"
            XCTAssertNil(paymentMethod?.metadata ?? 0)
            //#pragma clang diagnostic pop

            // Billing Details
            XCTAssertEqual(paymentMethod?.billingDetails.email, "jrosen@example.com")
            XCTAssertEqual(paymentMethod?.billingDetails.name, "Jenny Rosen")
            XCTAssertEqual(paymentMethod?.billingDetails.address.line1, "510 Townsend St.")
            XCTAssertEqual(paymentMethod?.billingDetails.address.postalCode, "94102")
            XCTAssertEqual(paymentMethod?.billingDetails.address.country, "US")

            XCTAssertNotNil(paymentMethod?.afterpayClearpay ?? 0)
        }

        waitForExpectations(timeout: TestConstants.stpTestingNetworkRequestTimeout, handler: nil)

    }
}
