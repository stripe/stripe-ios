//
//  STPPaymentMethodMultibancoTests.swift
//  StripeiOSTests
//
//  Created by Nick Porter on 4/22/24.
//

@testable import Stripe
import StripeCoreTestUtils
import XCTest

class STPPaymentMethodMultibancoTests: XCTestCase {

    static let multibancoPaymentIntentClientSecret = "TODO"

    func _retrieveMultibancoJSON(_ completion: @escaping ([AnyHashable: Any]?) -> Void) {
        let client = STPAPIClient(publishableKey: STPTestingFRPublishableKey)
        client.retrievePaymentIntent(
            withClientSecret: Self.multibancoPaymentIntentClientSecret,
            expand: ["payment_method"]
        ) { paymentIntent, _ in
            XCTAssertNotNil(paymentIntent?.paymentMethod?.allResponseFields["multibanco"])
            let multibancoJson = try? XCTUnwrap(paymentIntent?.paymentMethod?.multibanco?.allResponseFields)
            completion(multibancoJson)
        }
    }

    func testObjectDecoding() {
        let retrieveJSON = XCTestExpectation(description: "Retrieve JSON")

        _retrieveMultibancoJSON({ json in
            let multibanco = STPPaymentMethodMultibanco.decodedObject(fromAPIResponse: json)
            XCTAssertNotNil(multibanco, "Failed to decode JSON")
            retrieveJSON.fulfill()
        })

        wait(for: [retrieveJSON], timeout: STPTestingNetworkRequestTimeout)
    }

}
