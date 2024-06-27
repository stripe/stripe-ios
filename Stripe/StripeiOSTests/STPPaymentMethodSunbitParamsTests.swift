//
//  STPPaymentMethodSunbitParamsTests.swift
//  StripeiOSTests
//
//  Created by Eric Geniesse on 6/27/24.
//

import Foundation
import StripeCoreTestUtils

@testable@_spi(STP) import Stripe
@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePayments
@testable@_spi(STP) import StripePaymentSheet
@testable@_spi(STP) import StripePaymentsUI

class STPPaymentMethodSunbitParamsTests: XCTestCase {

    func testCreateSunbitPaymentMethod() throws {
        let sunbitParams = STPPaymentMethodSunbitParams()

        let params = STPPaymentMethodParams(
            sunbit: sunbitParams,
            billingDetails: nil,
            metadata: nil
        )

        let exp = expectation(description: "Payment Method Sunbit create")

        let client = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)
        client.createPaymentMethod(with: params) {
            (paymentMethod: STPPaymentMethod?, error: Error?) in
            exp.fulfill()

            XCTAssertNil(error)
            XCTAssertNotNil(paymentMethod, "Payment method should be populated")
            XCTAssertEqual(paymentMethod?.type, .sunbit, "Incorrect PaymentMethod type")
            XCTAssertNotNil(paymentMethod?.sunbit, "The `sunbit` property must be populated")
        }

        self.waitForExpectations(timeout: STPTestingNetworkRequestTimeout)
    }

}
