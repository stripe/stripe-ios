//
//  STPPaymentMethodVippsParamsTests.swift
//  StripeiOSTests
//

import StripeCoreTestUtils
import StripePaymentsTestUtils

@testable@_spi(STP) import Stripe

class STPPaymentMethodVippsParamsTests: STPNetworkStubbingTestCase {

    func testCreateVippsPaymentMethod() throws {
        let vippsParams = STPPaymentMethodVippsParams()

        let params = STPPaymentMethodParams(
            vipps: vippsParams,
            billingDetails: nil,
            metadata: nil
        )

        let exp = expectation(description: "Payment Method Vipps create")

        let client = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)
        client.createPaymentMethod(with: params) {
            (paymentMethod: STPPaymentMethod?, error: Error?) in
            exp.fulfill()

            XCTAssertNil(error)
            XCTAssertNotNil(paymentMethod, "Payment method should be populated")
            XCTAssertEqual(paymentMethod?.type, .vipps, "Incorrect PaymentMethod type")
            XCTAssertNotNil(paymentMethod?.vipps, "The `vipps` property must be populated")
        }

        waitForExpectations(timeout: STPTestingNetworkRequestTimeout)
    }
}
