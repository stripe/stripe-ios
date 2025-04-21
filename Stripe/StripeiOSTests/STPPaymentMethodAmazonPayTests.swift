//
//  STPPaymentMethodAmazonPayTests.swift
//  StripeiOSTests
//
//  Created by Nick Porter on 2/21/24.
//

@testable import Stripe
import StripeCoreTestUtils
import StripePaymentsTestUtils
import XCTest

class STPPaymentMethodAmazonPayTests: STPNetworkStubbingTestCase {

    static let amazonPayPaymentIntentClientSecret = "pi_3OmQQ0FY0qyl6XeW0H4X6eI0_secret_BerPIzUf8vFy1KXG53iYvX2Zb"

    func _retrieveAmazonPayJSON(_ completion: @escaping ([AnyHashable: Any]?) -> Void) {
        let client = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)
        client.retrievePaymentIntent(
            withClientSecret: Self.amazonPayPaymentIntentClientSecret,
            expand: ["payment_method"]
        ) { paymentIntent, _ in
            XCTAssertNotNil(paymentIntent?.paymentMethod?.allResponseFields["amazon_pay"])
            let amazonPayJson = try? XCTUnwrap(paymentIntent?.paymentMethod?.amazonPay?.allResponseFields)
            completion(amazonPayJson)
        }
    }

    func testObjectDecoding() {
        let retrieveJSON = XCTestExpectation(description: "Retrieve JSON")

        _retrieveAmazonPayJSON({ json in
            let amazonPay = STPPaymentMethodAmazonPay.decodedObject(fromAPIResponse: json)
            XCTAssertNotNil(amazonPay, "Failed to decode JSON")
            retrieveJSON.fulfill()
        })

        wait(for: [retrieveJSON], timeout: STPTestingNetworkRequestTimeout)
    }

}
