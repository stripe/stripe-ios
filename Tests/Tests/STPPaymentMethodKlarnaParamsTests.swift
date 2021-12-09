//
//  STPPaymentMethodKlarnaParamsTests.swift
//  StripeiOS Tests
//
//  Created by Nick Porter on 10/20/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation
import StripeCoreTestUtils
@testable import Stripe

class STPPaymentMethodKlarnaParamsTests: XCTestCase {

    func testCreateKlarnaPaymentMethod() throws {
        let klarnaParams = STPPaymentMethodKlarnaParams()

        let address = STPPaymentMethodAddress()
        address.line1 = "55 John St"
        address.line2 = "#3B"
        address.city = "New York"
        address.state = "NY"
        address.postalCode = "10002"
        address.country = "US"

        let billingDetails = STPPaymentMethodBillingDetails()
        billingDetails.name = "John Smith"
        billingDetails.email = "foo@example.com"
        billingDetails.address = address

        let params = STPPaymentMethodParams(
            klarna: klarnaParams,
            billingDetails: billingDetails,
            metadata: nil)

        let exp = expectation(description: "Payment Method Klarna create")

        let client = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)
        client.createPaymentMethod(with: params) { (paymentMethod: STPPaymentMethod?, error: Error?) in
            exp.fulfill()

            XCTAssertNil(error);
            XCTAssertNotNil(paymentMethod, "Payment method should be populated");
            XCTAssertEqual(paymentMethod?.type, .klarna, "Incorrect PaymentMethod type");

            XCTAssertEqual(
                paymentMethod?.billingDetails?.name, "John Smith",
                "Billing name should match the name provided during creation"
            )

            XCTAssertEqual(
                paymentMethod?.billingDetails?.email, "foo@example.com",
                "Billing email should match the name provided during creation"
            )

            XCTAssertNotNil(paymentMethod?.klarna, "The `klarna` property must be populated");
        }

        self.waitForExpectations(timeout: STPTestingNetworkRequestTimeout)
    }

}
