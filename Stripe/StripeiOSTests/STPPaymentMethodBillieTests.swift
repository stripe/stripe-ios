//
//  STPPaymentMethodBillieTests.swift
//  StripeiOSTests
//
//  Created by Eric Geniesse on 6/28/24.
//

@testable import Stripe
import StripeCoreTestUtils
import XCTest

class STPPaymentMethodBillieTests: XCTestCase {

    static let billiePaymentIntentClientSecret = "pi_3PWj22Alz2yHYCNZ0vnWGOMN_secret_8eUe1QkN5OVMY0323P4rsYPvv"

    func _retrieveBillieJSON(_ completion: @escaping ([AnyHashable: Any]?) -> Void) {
        let client = STPAPIClient(publishableKey: STPTestingDEPublishableKey)
        client.retrievePaymentIntent(
            withClientSecret: Self.billiePaymentIntentClientSecret,
            expand: ["payment_method"]
        ) { paymentIntent, _ in
            XCTAssertNotNil(paymentIntent?.paymentMethod?.allResponseFields["billie"])
            let billieJson = try? XCTUnwrap(paymentIntent?.paymentMethod?.billie?.allResponseFields)
            completion(billieJson)
        }
    }

    func testObjectDecoding() {
        let retrieveJSON = XCTestExpectation(description: "Retrieve JSON")

        _retrieveBillieJSON({ json in
            let billie = STPPaymentMethodBillie.decodedObject(fromAPIResponse: json)
            XCTAssertNotNil(billie, "Failed to decode JSON")
            retrieveJSON.fulfill()
        })

        wait(for: [retrieveJSON], timeout: STPTestingNetworkRequestTimeout)
    }
}
