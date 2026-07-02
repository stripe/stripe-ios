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
        "pi_3VippsKG6vc7r7YC1Xs7oiWw_secret_5cqzEtQ059azmV1GmkLRA7Lvt"

    func _retrieveVippsJSON(_ completion: @escaping ([AnyHashable: Any]?) -> Void) {
        let client = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)
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
