//
//  STPPaymentMethodMultibancoParamsTests.swift
//  StripeiOSTests
//
//  Created by Nick Porter on 4/22/24.
//

import Foundation
import StripeCoreTestUtils
import StripePaymentsTestUtils

@testable@_spi(STP) import Stripe
@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePayments
@testable@_spi(STP) import StripePaymentSheet
@testable@_spi(STP) import StripePaymentsUI

class STPPaymentMethodMultibancoParamsTests: STPNetworkStubbingTestCase {

    func testCreateMultibancoPaymentMethod() throws {
        let multibancoParams = STPPaymentMethodMultibancoParams()
        let billingDetails = STPPaymentMethodBillingDetails()
        billingDetails.email = "tester@example.com"

        let params = STPPaymentMethodParams(
            multibanco: multibancoParams,
            billingDetails: billingDetails,
            metadata: nil
        )

        let exp = expectation(description: "Payment Method Multibanco create")

        let client = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)
        client.createPaymentMethod(with: params) {
            (paymentMethod: STPPaymentMethod?, error: Error?) in
            exp.fulfill()

            XCTAssertNil(error)
            XCTAssertNotNil(paymentMethod, "Payment method should be populated")
            XCTAssertEqual(paymentMethod?.type, .multibanco, "Incorrect PaymentMethod type")
            XCTAssertNotNil(paymentMethod?.multibanco, "The `multibanco` property must be populated")
        }

        self.waitForExpectations(timeout: STPTestingNetworkRequestTimeout)
    }

}
