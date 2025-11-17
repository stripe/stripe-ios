//
//  STPPaymentMethodAffirmParamsTest.swift
//  StripeiOS Tests
//
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
@testable@_spi(STP) import Stripe
@testable@_spi(STP) import StripeCore
import StripeCoreTestUtils
@testable@_spi(STP) import StripePayments
@testable@_spi(STP) import StripePaymentSheet
import StripePaymentsTestUtils
@testable@_spi(STP) import StripePaymentsUI

class STPPaymentMethodAffirmParamsTests: STPNetworkStubbingTestCase {

    func testCreateAffirmPaymentMethod() throws {
        let affirmParams = STPPaymentMethodAffirmParams()

        let params = STPPaymentMethodParams(
            affirm: affirmParams,
            metadata: nil
        )

        let exp = expectation(description: "Payment Method Affirm create")

        let client = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)
        client.createPaymentMethod(with: params) {
            (paymentMethod: STPPaymentMethod?, error: Error?) in
            exp.fulfill()

            XCTAssertNil(error)
            XCTAssertNotNil(paymentMethod, "Payment method should be populated")
            XCTAssertEqual(paymentMethod?.type, .affirm, "Incorrect PaymentMethod type")
            XCTAssertNotNil(paymentMethod?.affirm, "The `affirm` property must be populated")
        }

        self.waitForExpectations(timeout: STPTestingNetworkRequestTimeout)
    }

    func testCreateAffirmPaymentMethodWithBillingDetails() throws {
        let affirmParams = STPPaymentMethodAffirmParams()

        let billingDetails = STPPaymentMethodBillingDetails()
        billingDetails.name = "Jane Doe"
        billingDetails.email = "jane@example.com"

        let address = STPPaymentMethodAddress()
        address.line1 = "510 Townsend St"
        address.city = "San Francisco"
        address.state = "CA"
        address.postalCode = "94102"
        address.country = "US"
        billingDetails.address = address

        let params = STPPaymentMethodParams(
            affirm: affirmParams,
            billingDetails: billingDetails,
            metadata: nil
        )

        let exp = expectation(description: "Payment Method Affirm create with billing details")

        let client = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)
        client.createPaymentMethod(with: params) {
            (paymentMethod: STPPaymentMethod?, error: Error?) in
            exp.fulfill()

            XCTAssertNil(error)
            XCTAssertNotNil(paymentMethod, "Payment method should be populated")
            XCTAssertEqual(paymentMethod?.type, .affirm, "Incorrect PaymentMethod type")
            XCTAssertNotNil(paymentMethod?.affirm, "The `affirm` property must be populated")
            XCTAssertEqual(paymentMethod?.billingDetails?.name, "Jane Doe")
            XCTAssertEqual(paymentMethod?.billingDetails?.email, "jane@example.com")
        }

        self.waitForExpectations(timeout: STPTestingNetworkRequestTimeout)
    }

}
