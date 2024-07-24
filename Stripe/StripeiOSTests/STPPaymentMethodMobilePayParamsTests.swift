//
//  STPPaymentMethodMobilePayParamsTests.swift
//  StripeiOSTests
//

import Foundation
import StripeCoreTestUtils
import StripePaymentsTestUtils

@testable@_spi(STP) import Stripe
@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePayments
@testable@_spi(STP) import StripePaymentSheet
@testable@_spi(STP) import StripePaymentsUI

class STPPaymentMethodMobilePayParamsTests: STPNetworkStubbingTestCase {

    func testCreateMobilePayPaymentMethod() throws {
        let mobilePayParams = STPPaymentMethodMobilePayParams()

        let params = STPPaymentMethodParams(
            mobilePay: mobilePayParams,
            billingDetails: nil,
            metadata: nil
        )

        let exp = expectation(description: "Payment Method MobilePay create")

        let client = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)
        client.createPaymentMethod(with: params) {
            (paymentMethod: STPPaymentMethod?, error: Error?) in
            exp.fulfill()

            XCTAssertNil(error)
            XCTAssertNotNil(paymentMethod, "Payment method should be populated")
            XCTAssertEqual(paymentMethod?.type, .mobilePay, "Incorrect PaymentMethod type")
            XCTAssertNotNil(paymentMethod?.mobilePay, "The `mobilepay` property must be populated")
        }

        self.waitForExpectations(timeout: STPTestingNetworkRequestTimeout)
    }

}
