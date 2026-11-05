//
//  STPPaymentMethodBillieParamsTests.swift
//  StripeiOSTests
//
//  Created by Eric Geniesse on 6/28/24.
//

import Foundation
import StripeCoreTestUtils

@testable@_spi(InternalOnlyAPI) import Stripe
@testable@_spi(InternalOnlyAPI) import StripeCore
@testable@_spi(InternalOnlyAPI) import StripePayments
@testable@_spi(InternalOnlyAPI) import StripePaymentSheet
import StripePaymentsTestUtils
@testable@_spi(InternalOnlyAPI) import StripePaymentsUI
import XCTest

class STPPaymentMethodBillieParamsTests: XCTestCase {

    func testCreateBilliePaymentMethod() throws {
        let billieParams = STPPaymentMethodBillieParams()

        let params = STPPaymentMethodParams(
            billie: billieParams,
            billingDetails: nil,
            metadata: nil
        )

        let exp = expectation(description: "Payment Method Billie create")

        let client = STPAPIClient(publishableKey: STPTestingDEPublishableKey)
        client.createPaymentMethod(with: params) {
            (paymentMethod: STPPaymentMethod?, error: Error?) in
            exp.fulfill()

            XCTAssertNil(error)
            XCTAssertNotNil(paymentMethod, "Payment method should be populated")
            XCTAssertEqual(paymentMethod?.type, .billie, "Incorrect PaymentMethod type")
            XCTAssertNotNil(paymentMethod?.billie, "The `billie` property must be populated")
        }

        self.waitForExpectations(timeout: STPTestingNetworkRequestTimeout)
    }

}
