//
//  STPPaymentMethodSunbitTests.swift
//  StripeiOSTests
//
//  Created by Eric Geniesse on 6/27/24.
//

@testable import Stripe
import StripeCoreTestUtils
import XCTest

class STPPaymentMethodSunbitTests: XCTestCase {

    static let sunbitPaymentIntentClientSecret = "pi_3PXmrrFY0qyl6XeW1KiGqDLP_secret_zAZk6ZD3cLPwb2lB6wTcLAhLU"

    func _retrieveSunbitJSON(_ completion: @escaping ([AnyHashable: Any]?) -> Void) {
        let client = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)
        client.retrievePaymentIntent(
            withClientSecret: Self.sunbitPaymentIntentClientSecret,
            expand: ["payment_method"]
        ) { paymentIntent, _ in
            XCTAssertNotNil(paymentIntent?.paymentMethod?.allResponseFields["sunbit"])
            let sunbitJson = try? XCTUnwrap(paymentIntent?.paymentMethod?.sunbit?.allResponseFields)
            completion(sunbitJson)
        }
    }

    func testObjectDecoding() {
        let retrieveJSON = XCTestExpectation(description: "Retrieve JSON")

        _retrieveSunbitJSON({ json in
            let sunbit = STPPaymentMethodSunbit.decodedObject(fromAPIResponse: json)
            XCTAssertNotNil(sunbit, "Failed to decode JSON")
            retrieveJSON.fulfill()
        })

        wait(for: [retrieveJSON], timeout: STPTestingNetworkRequestTimeout)
    }
}
