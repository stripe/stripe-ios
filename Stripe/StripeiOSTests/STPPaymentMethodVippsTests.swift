//
//  STPPaymentMethodVippsTests.swift
//  StripeiOSTests
//

@testable import Stripe
import StripeCoreTestUtils
import StripePaymentsTestUtils
import XCTest

class STPPaymentMethodVippsTests: STPNetworkStubbingTestCase {

    static let vippsPaymentIntentClientSecret =
        "pi_3U434fKG6vc7r7YC1UIzHbsV_secret_HATDeUfLrlwd7tflltM4lm9SS"

    func _retrieveVippsJSON(_ completion: @escaping ([AnyHashable: Any]?) -> Void) {
        let client = STPAPIClient(publishableKey: STPTestingFRPublishableKey)
        client.betas = ["vipps_preview=v1"]
        client.retrievePaymentIntent(
            withClientSecret: Self.vippsPaymentIntentClientSecret,
            expand: ["payment_method"]
        ) { paymentIntent, _ in
            XCTAssertNotNil(paymentIntent?.paymentMethod?.allResponseFields["vipps"])
            let vippsJSON = try? XCTUnwrap(paymentIntent?.paymentMethod?.vipps?.allResponseFields)
            completion(vippsJSON)
        }
    }

    func testObjectDecoding() {
        let retrieveJSON = XCTestExpectation(description: "Retrieve JSON")

        _retrieveVippsJSON { json in
            let vipps = STPPaymentMethodVipps.decodedObject(fromAPIResponse: json)
            XCTAssertNotNil(vipps, "Failed to decode JSON")
            retrieveJSON.fulfill()
        }

        wait(for: [retrieveJSON], timeout: STPTestingNetworkRequestTimeout)
    }
}
