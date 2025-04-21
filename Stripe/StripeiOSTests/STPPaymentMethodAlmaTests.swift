//
//  STPPaymentMethodAlmaTests.swift
//  StripeiOSTests
//
//  Created by Nick Porter on 3/27/24.
//

@testable import Stripe
import StripeCoreTestUtils
import StripePaymentsTestUtils
import XCTest

class STPPaymentMethodAlmaTests: STPNetworkStubbingTestCase {

    static let almaPaymentIntentClientSecret = "pi_3Oz1AfKG6vc7r7YC0VaP6KiE_secret_SxVptpJ5PaAceAYCGetQh8FVv"

    func _retrieveAlmaJSON(_ completion: @escaping ([AnyHashable: Any]?) -> Void) {
        let client = STPAPIClient(publishableKey: STPTestingFRPublishableKey)
        client.retrievePaymentIntent(
            withClientSecret: Self.almaPaymentIntentClientSecret,
            expand: ["payment_method"]
        ) { paymentIntent, _ in
            XCTAssertNotNil(paymentIntent?.paymentMethod?.allResponseFields["alma"])
            let almaJson = try? XCTUnwrap(paymentIntent?.paymentMethod?.alma?.allResponseFields)
            completion(almaJson)
        }
    }

    func testObjectDecoding() {
        let retrieveJSON = XCTestExpectation(description: "Retrieve JSON")

        _retrieveAlmaJSON({ json in
            let alma = STPPaymentMethodAlma.decodedObject(fromAPIResponse: json)
            XCTAssertNotNil(alma, "Failed to decode JSON")
            retrieveJSON.fulfill()
        })

        wait(for: [retrieveJSON], timeout: STPTestingNetworkRequestTimeout)
    }

}
