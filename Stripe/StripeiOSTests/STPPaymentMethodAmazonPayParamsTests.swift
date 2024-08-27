//
//  STPPaymentMethodAmazonPayParamsTests.swift
//  StripeiOSTests
//
//  Created by Nick Porter on 2/21/24.
//

import Foundation
import StripeCoreTestUtils

@testable@_spi(STP) import Stripe
@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePayments
@testable@_spi(STP) import StripePaymentSheet
import StripePaymentsTestUtils
@testable@_spi(STP) import StripePaymentsUI

class STPPaymentMethodAmazonPayParamsTests: STPNetworkStubbingTestCase {

    func testCreateAmazonPayPaymentMethod() throws {
        let amazonPayParams = STPPaymentMethodAmazonPayParams()

        let params = STPPaymentMethodParams(
            amazonPay: amazonPayParams,
            billingDetails: nil,
            metadata: nil
        )

        let exp = expectation(description: "Payment Method Amazon Pay create")

        let client = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)
        client.createPaymentMethod(with: params) {
            (paymentMethod: STPPaymentMethod?, error: Error?) in
            exp.fulfill()

            XCTAssertNil(error)
            XCTAssertNotNil(paymentMethod, "Payment method should be populated")
            XCTAssertEqual(paymentMethod?.type, .amazonPay, "Incorrect PaymentMethod type")
            XCTAssertNotNil(paymentMethod?.amazonPay, "The `amazonPay` property must be populated")
        }

        self.waitForExpectations(timeout: STPTestingNetworkRequestTimeout)
    }

}
