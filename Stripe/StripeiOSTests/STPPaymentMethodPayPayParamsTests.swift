//
//  STPPaymentMethodPayPayParamsTests.swift
//  StripeiOSTests
//
//  Created by Joyce Qin on 12/2/25.
//

import Foundation
@testable@_spi(STP) import Stripe
@testable@_spi(STP) import StripeCore
import StripeCoreTestUtils
@testable@_spi(STP) import StripePayments
@testable@_spi(STP) import StripePaymentSheet
import StripePaymentsTestUtils
@testable@_spi(STP) import StripePaymentsUI

class STPPaymentMethodPayPayParamsTests: STPNetworkStubbingTestCase {

    func testCreatePayPayPaymentMethod() throws {
        let payPayParams = STPPaymentMethodPayPayParams()

        let params = STPPaymentMethodParams(
            payPay: payPayParams,
            metadata: nil
        )

        let exp = expectation(description: "Payment Method PayPay create")

        let client = STPAPIClient(publishableKey: STPTestingJPPublishableKey)
        client.createPaymentMethod(with: params) {
            (paymentMethod: STPPaymentMethod?, error: Error?) in
            exp.fulfill()

            XCTAssertNil(error)
            XCTAssertNotNil(paymentMethod, "Payment method should be populated")
            XCTAssertEqual(paymentMethod?.type, .payPay, "Incorrect PaymentMethod type")
            XCTAssertNotNil(paymentMethod?.payPay, "The `payPay` property must be populated")
        }

        self.waitForExpectations(timeout: STPTestingNetworkRequestTimeout)
    }

}
