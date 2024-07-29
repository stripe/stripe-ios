//
//  STPPaymentMethodAlmaParamsTests.swift
//  StripeiOSTests
//
//  Created by Nick Porter on 3/27/24.
//

import Foundation
import StripeCoreTestUtils
import StripePaymentsTestUtils

@testable@_spi(STP) import Stripe
@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePayments
@testable@_spi(STP) import StripePaymentSheet
@testable@_spi(STP) import StripePaymentsUI

class STPPaymentMethodAlmaParamsTests: STPNetworkStubbingTestCase {

    func testCreateAlmaPaymentMethod() throws {
        let almaParams = STPPaymentMethodAlmaParams()

        let params = STPPaymentMethodParams(
            alma: almaParams,
            billingDetails: nil,
            metadata: nil
        )

        let exp = expectation(description: "Payment Method Alma create")

        let client = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)
        client.createPaymentMethod(with: params) {
            (paymentMethod: STPPaymentMethod?, error: Error?) in
            exp.fulfill()

            XCTAssertNil(error)
            XCTAssertNotNil(paymentMethod, "Payment method should be populated")
            XCTAssertEqual(paymentMethod?.type, .alma, "Incorrect PaymentMethod type")
            XCTAssertNotNil(paymentMethod?.alma, "The `alma` property must be populated")
        }

        self.waitForExpectations(timeout: STPTestingNetworkRequestTimeout)
    }

}
