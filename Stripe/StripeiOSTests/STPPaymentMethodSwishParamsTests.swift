//
//  STPPaymentMethodSwishParamsTests.swift
//  StripeiOSTests
//
//  Created by Eduardo Urias on 9/21/23.
//

import Foundation
@testable @_spi(STP) import StripeCoreTestUtils
@testable @_spi(STP) import StripePayments
import StripePaymentsTestUtils

class STPPaymentMethodSwishParamsTests: STPNetworkStubbingTestCase {

    func testCreateSwishPaymentMethod() throws {
        let swishParams = STPPaymentMethodSwishParams()

        let params = STPPaymentMethodParams(
            swish: swishParams,
            billingDetails: nil,
            metadata: nil
        )

        let exp = expectation(description: "Payment Method Swish create")

        let client = STPAPIClient(publishableKey: STPTestingFRPublishableKey)
        client.createPaymentMethod(with: params) {
            (paymentMethod: STPPaymentMethod?, error: Error?) in
            exp.fulfill()

            XCTAssertNil(error)
            XCTAssertNotNil(paymentMethod, "Payment method should be populated")
            XCTAssertEqual(paymentMethod?.type, .swish, "Incorrect PaymentMethod type")
            XCTAssertNotNil(paymentMethod?.swish, "The `swish` property must be populated")
        }

        self.waitForExpectations(timeout: STPTestingNetworkRequestTimeout)
    }

}
