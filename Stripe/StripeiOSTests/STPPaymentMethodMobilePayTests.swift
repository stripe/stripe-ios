//
//  STPPaymentMethodMobilePayTests.swift
//  StripeiOSTests
//

@testable import Stripe
import StripeCoreTestUtils
import StripePaymentsTestUtils
import XCTest

class STPPaymentMethodMobilePayTests: STPNetworkStubbingTestCase {

    static let mobilePayPaymentIntentClientSecret = "pi_3PGVQJKG6vc7r7YC1Xs7oiWw_secret_5cqzEtQ059azmV1GmkLRA7Lvt"

    func _retrieveMobilePayJSON(_ completion: @escaping ([AnyHashable: Any]?) -> Void) {
        let client = STPAPIClient(publishableKey: STPTestingFRPublishableKey)
        client.retrievePaymentIntent(
            withClientSecret: Self.mobilePayPaymentIntentClientSecret,
            expand: ["payment_method"]
        ) { paymentIntent, _ in
            XCTAssertNotNil(paymentIntent?.paymentMethod?.allResponseFields["mobilepay"])
            let mobilePayJson = try? XCTUnwrap(paymentIntent?.paymentMethod?.mobilePay?.allResponseFields)
            completion(mobilePayJson)
        }
    }

    func testObjectDecoding() {
        let retrieveJSON = XCTestExpectation(description: "Retrieve JSON")

        _retrieveMobilePayJSON({ json in
            let mobilePay = STPPaymentMethodMobilePay.decodedObject(fromAPIResponse: json)
            XCTAssertNotNil(mobilePay, "Failed to decode JSON")
            retrieveJSON.fulfill()
        })

        wait(for: [retrieveJSON], timeout: STPTestingNetworkRequestTimeout)
    }

}
