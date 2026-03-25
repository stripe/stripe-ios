//
//  STPPaymentMethodWeroTests.swift
//  StripeiOSTests
//
//  Created by Nick Porter on 3/6/26.
//

@testable import Stripe
import StripeCoreTestUtils
import XCTest

class STPPaymentMethodWeroTests: XCTestCase {

    static let weroPaymentIntentClientSecret = "pi_3T82L9Alz2yHYCNZ1MoVLb9X_secret_l4KRqA7YlQnUYgHnw7pjXf1H3"

    func _retrieveWeroJSON(_ completion: @escaping ([AnyHashable: Any]?) -> Void) {
        let client = STPAPIClient(publishableKey: STPTestingDEPublishableKey)
        client.retrievePaymentIntent(
            withClientSecret: Self.weroPaymentIntentClientSecret,
            expand: ["payment_method"]
        ) { paymentIntent, _ in
            XCTAssertNotNil(paymentIntent?.paymentMethod?.allResponseFields["wero"])
            let weroJson = try? XCTUnwrap(paymentIntent?.paymentMethod?.wero?.allResponseFields)
            completion(weroJson)
        }
    }

    func testObjectDecoding() {
        let retrieveJSON = XCTestExpectation(description: "Retrieve JSON")

        _retrieveWeroJSON({ json in
            let wero = STPPaymentMethodWero.decodedObject(fromAPIResponse: json)
            XCTAssertNotNil(wero, "Failed to decode JSON")
            retrieveJSON.fulfill()
        })

        wait(for: [retrieveJSON], timeout: STPTestingNetworkRequestTimeout)
    }
}
