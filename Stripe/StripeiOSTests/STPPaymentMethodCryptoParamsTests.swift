//
//  STPPaymentMethodCryptoParamsTests.swift
//  StripeiOSTests
//
//  Created by Eric Zhang on 11/20/24.
//

import Foundation
import StripeCoreTestUtils

@testable@_spi(STP) import Stripe
@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePayments
@testable@_spi(STP) import StripePaymentSheet
@testable@_spi(STP) import StripePaymentsUI

class STPPaymentMethodCryptoParamsTests: XCTestCase {

    func testCreateCryptoPaymentMethod() throws {
        let cryptoParams = STPPaymentMethodCryptoParams()

        let params = STPPaymentMethodParams(
            crypto: cryptoParams,
            billingDetails: nil,
            metadata: nil
        )

        let exp = expectation(description: "Payment Method Crypto create")

        let client = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)
        client.createPaymentMethod(with: params) {
            (paymentMethod: STPPaymentMethod?, error: Error?) in
            exp.fulfill()

            XCTAssertNil(error)
            XCTAssertNotNil(paymentMethod, "Payment method should be populated")
            XCTAssertEqual(paymentMethod?.type, .crypto, "Incorrect PaymentMethod type")
            XCTAssertNotNil(paymentMethod?.crypto, "The `crypto` property must be populated")
        }

        self.waitForExpectations(timeout: STPTestingNetworkRequestTimeout)
    }

}
