//
//  STPPaymentMethodCashAppParamsTests.swift
//  StripeiOSTests
//
//  Created by Nick Porter on 1/4/23.
//

import Foundation
import StripeCoreTestUtils

@testable@_spi(STP) import Stripe
@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePayments
@testable@_spi(STP) import StripePaymentSheet
@testable@_spi(STP) import StripePaymentsUI

class STPPaymentMethodCashAppParamsTests: XCTestCase {

    func testCreateCashAppPaymentMethod() throws {
        let cashAppParams = STPPaymentMethodCashAppParams()

        let params = STPPaymentMethodParams(
            cashApp: cashAppParams,
            billingDetails: nil,
            metadata: nil
        )

        let exp = expectation(description: "Payment Method Cash App create")

        let client = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)
        client.createPaymentMethod(with: params) {
            (paymentMethod: STPPaymentMethod?, error: Error?) in
            exp.fulfill()

            XCTAssertNil(error)
            XCTAssertNotNil(paymentMethod, "Payment method should be populated")
            XCTAssertEqual(paymentMethod?.type, .cashApp, "Incorrect PaymentMethod type")
            XCTAssertNotNil(paymentMethod?.cashApp, "The `cashApp` property must be populated")
        }

        self.waitForExpectations(timeout: STPTestingNetworkRequestTimeout)
    }

}
