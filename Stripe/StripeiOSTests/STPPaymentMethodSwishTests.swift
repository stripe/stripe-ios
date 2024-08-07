//
//  STPPaymentMethodSwishTests.swift
//  StripeiOSTests
//
//  Created by Eduardo Urias on 9/21/23.
//

import Foundation
import StripePaymentsTestUtils

@testable @_spi(STP) import StripeCoreTestUtils
@testable @_spi(STP) import StripePayments

class STPPaymentMethodSwishTests: STPNetworkStubbingTestCase {

    static let swishPaymentIntentClientSecret =
        "pi_3Nsu6oKG6vc7r7YC1FJJPNjg_secret_wQtTkgmjgOMSqN7lje5RCtzrm"

    func _retrieveSwishJSON(_ completion: @escaping ([AnyHashable: Any]?) -> Void) {
        let client = STPAPIClient(publishableKey: STPTestingFRPublishableKey)
        client.retrievePaymentIntent(
            withClientSecret: Self.swishPaymentIntentClientSecret,
            expand: ["payment_method"]
        ) { paymentIntent, _ in
            let swishJson = paymentIntent?.paymentMethod?.swish?.allResponseFields
            completion(swishJson)
        }
    }

    func testObjectDecoding() {
        let retrieveJSON = XCTestExpectation(description: "Retrieve JSON")

        _retrieveSwishJSON({ json in
            let klarna = STPPaymentMethodSwish.decodedObject(fromAPIResponse: json)
            XCTAssertNotNil(klarna, "Failed to decode JSON")
            retrieveJSON.fulfill()
        })

        wait(for: [retrieveJSON], timeout: STPTestingNetworkRequestTimeout)
    }

}
