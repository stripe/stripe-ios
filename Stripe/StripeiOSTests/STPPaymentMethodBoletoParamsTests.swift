//
//  STPPaymentMethodBoletoParamsTests.swift
//  StripeiOS Tests
//
//  Created by Ramon Torres on 9/9/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import StripeCoreTestUtils
import XCTest

@testable@_spi(STP) import Stripe
@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePayments
@testable@_spi(STP) import StripePaymentSheet
@testable@_spi(STP) import StripePaymentsUI

class STPPaymentMethodBoletoParamsTests: XCTestCase {

    func testCreateBoletoPaymentMethod() throws {
        let boletoParams = STPPaymentMethodBoletoParams()
        boletoParams.taxID = "00.000.000/0001-91"

        let address = STPPaymentMethodAddress()
        address.line1 = "Av. Do Brasil 1374"
        address.city = "Sao Paulo"
        address.state = "SP"
        address.postalCode = "01310100"
        address.country = "BR"

        let billingDetails = STPPaymentMethodBillingDetails()
        billingDetails.name = "Jane Diaz"
        billingDetails.email = "jane@example.com"
        billingDetails.address = address

        let params = STPPaymentMethodParams(
            boleto: boletoParams,
            billingDetails: billingDetails,
            metadata: nil
        )

        let exp = expectation(description: "Payment Method Boleto create")

        let client = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)
        client.createPaymentMethod(with: params) {
            (paymentMethod: STPPaymentMethod?, error: Error?) in
            exp.fulfill()

            XCTAssertNil(error)
            XCTAssertNotNil(paymentMethod, "Payment method should be populated")
            XCTAssertEqual(paymentMethod?.type, .boleto, "Incorrect PaymentMethod type")

            XCTAssertEqual(
                paymentMethod?.billingDetails?.name,
                "Jane Diaz",
                "Billing name should match the name provided during creation"
            )

            XCTAssertEqual(
                paymentMethod?.billingDetails?.email,
                "jane@example.com",
                "Billing email should match the name provided during creation"
            )

            XCTAssertNotNil(paymentMethod?.boleto, "The `boleto` property must be populated")
        }

        self.waitForExpectations(timeout: STPTestingNetworkRequestTimeout)
    }

}
