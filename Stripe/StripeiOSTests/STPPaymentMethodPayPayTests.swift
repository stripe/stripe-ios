//
//  STPPaymentMethodPayPayTests.swift
//  StripeiOSTests
//
//  Created by Joyce Qin on 12/2/25.
//

import StripeCoreTestUtils
import StripePaymentsTestUtils
import XCTest

@testable@_spi(STP) import Stripe
@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePayments
@testable@_spi(STP) import StripePaymentsUI

class STPPaymentMethodPayPayTests: STPNetworkStubbingTestCase {

    static let payPayPaymentIntentClientSecret =
        "pi_3SZwa9Iq2LmpyICo0mb0N9jg_secret_W2spdkzdHkt2K74RdfCHhudQp"

    func _retrievePayPayJSON(_ completion: @escaping ([AnyHashable: Any]?) -> Void) {
        let client = STPAPIClient(publishableKey: STPTestingJPPublishableKey)
        client.retrievePaymentIntent(
            withClientSecret: Self.payPayPaymentIntentClientSecret,
            expand: ["payment_method"]
        ) { paymentIntent, _ in
            let payPayJson = paymentIntent?.paymentMethod?.payPay?.allResponseFields
            XCTAssertNotNil(paymentIntent?.paymentMethod?.payPay)
            completion(payPayJson ?? [:])
        }
    }

    func testObjectDecoding() {
        let retrieveJSON = XCTestExpectation(description: "Retrieve JSON")

        _retrievePayPayJSON({ json in
            let payPay = STPPaymentMethodPayPay.decodedObject(fromAPIResponse: json)
            XCTAssertNotNil(payPay, "Failed to decode JSON")
            retrieveJSON.fulfill()
        })

        wait(for: [retrieveJSON], timeout: STPTestingNetworkRequestTimeout)
    }

}
