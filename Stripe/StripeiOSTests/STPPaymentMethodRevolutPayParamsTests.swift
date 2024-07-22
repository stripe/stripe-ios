//
//  STPPaymentMethodRevolutPayParamsTests.swift
//  StripeiOSTests
//

import Foundation
import StripeCoreTestUtils

@testable@_spi(STP) import Stripe
@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePayments
@testable@_spi(STP) import StripePaymentSheet
import StripePaymentsTestUtils
@testable@_spi(STP) import StripePaymentsUI

class STPPaymentMethodRevolutPayParamsTests: STPNetworkStubbingTestCase {

    func testCreateRevolutPayPaymentMethod() throws {
        let revolutPayParams = STPPaymentMethodRevolutPayParams()

        let params = STPPaymentMethodParams(
            revolutPay: revolutPayParams,
            billingDetails: nil,
            metadata: nil
        )

        let exp = expectation(description: "Payment Method Revolut Pay create")

        let client = STPAPIClient(publishableKey: STPTestingGBPublishableKey)
        client.createPaymentMethod(with: params) {
            (paymentMethod: STPPaymentMethod?, error: Error?) in
            exp.fulfill()

            XCTAssertNil(error)
            XCTAssertNotNil(paymentMethod, "Payment method should be populated")
            XCTAssertEqual(paymentMethod?.type, .revolutPay, "Incorrect PaymentMethod type")
            XCTAssertNotNil(paymentMethod?.revolutPay, "The `revolut_pay` property must be populated")
        }

        self.waitForExpectations(timeout: STPTestingNetworkRequestTimeout)
    }

}
