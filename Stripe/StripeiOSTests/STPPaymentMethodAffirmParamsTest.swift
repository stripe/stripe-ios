//
//  STPPaymentMethodAffirmParamsTest.swift
//  StripeiOS Tests
//
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
import StripeCoreTestUtils

@testable@_spi(STP) import Stripe
@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePayments
@testable@_spi(STP) import StripePaymentSheet
@testable@_spi(STP) import StripePaymentsUI

class STPPaymentMethodAffirmParamsTests: XCTestCase {

    func testCreateAffirmPaymentMethod() throws {
        let affirmParams = STPPaymentMethodAffirmParams()

        let params = STPPaymentMethodParams(
            affirm: affirmParams,
            metadata: nil
        )

        let exp = expectation(description: "Payment Method Affirm create")

        let client = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)
        client.createPaymentMethod(with: params) {
            (paymentMethod: STPPaymentMethod?, error: Error?) in
            exp.fulfill()

            XCTAssertNil(error)
            XCTAssertNotNil(paymentMethod, "Payment method should be populated")
            XCTAssertEqual(paymentMethod?.type, .affirm, "Incorrect PaymentMethod type")
            XCTAssertNotNil(paymentMethod?.affirm, "The `affirm` property must be populated")
        }

        self.waitForExpectations(timeout: STPTestingNetworkRequestTimeout)
    }

}
