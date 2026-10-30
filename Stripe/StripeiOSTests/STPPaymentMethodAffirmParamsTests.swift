//
//  STPPaymentMethodAffirmParamsTests.swift
//  StripeiOS Tests
//
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
@testable@_spi(InternalOnlyAPI) import Stripe
@testable@_spi(InternalOnlyAPI) import StripeCore
import StripeCoreTestUtils
@testable@_spi(InternalOnlyAPI) import StripePayments
@testable@_spi(InternalOnlyAPI) import StripePaymentSheet
import StripePaymentsTestUtils
@testable@_spi(InternalOnlyAPI) import StripePaymentsUI

class STPPaymentMethodAffirmParamsTests: STPNetworkStubbingTestCase {

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
