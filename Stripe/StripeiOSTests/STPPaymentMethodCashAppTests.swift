//
//  STPPaymentMethodCashAppTests.swift
//  StripeiOSTests
//
//  Created by Nick Porter on 1/4/23.
//

@testable import Stripe
import StripeCoreTestUtils
import XCTest

class STPPaymentMethodCashAppTests: XCTestCase {

    static let cashAppPaymentIntentClientSecret = "pi_3MMa4NFY0qyl6XeW1FM3HOts_secret_b4HQ5YksK3mfe7zZaxBlWCark"

    func _retrieveCashAppJSON(_ completion: @escaping ([AnyHashable: Any]?) -> Void) {
        let client = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)
        client.retrievePaymentIntent(
            withClientSecret: Self.cashAppPaymentIntentClientSecret,
            expand: ["payment_method"]
        ) { paymentIntent, _ in
            XCTAssertNotNil(paymentIntent?.paymentMethod?.allResponseFields["cashapp"])
            let cashAppJson = try? XCTUnwrap(paymentIntent?.paymentMethod?.cashApp?.allResponseFields)
            completion(cashAppJson)
        }
    }

    func testObjectDecoding() {
        let retrieveJSON = XCTestExpectation(description: "Retrieve JSON")

        _retrieveCashAppJSON({ json in
            let cashApp = STPPaymentMethodCashApp.decodedObject(fromAPIResponse: json)
            XCTAssertNotNil(cashApp, "Failed to decode JSON")
            retrieveJSON.fulfill()
        })

        wait(for: [retrieveJSON], timeout: STPTestingNetworkRequestTimeout)
    }

}
