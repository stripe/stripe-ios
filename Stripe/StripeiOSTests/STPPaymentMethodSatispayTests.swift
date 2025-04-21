//
//  STPPaymentMethodSatispayTests.swift
//  StripeiOSTests
//
//  Created by Eric Geniesse on 7/1/24.
//

@testable import Stripe
import StripeCoreTestUtils
import XCTest
@testable@_spi(STP) import StripePaymentsTestUtils

class STPPaymentMethodSatispayTests: STPNetworkStubbingTestCase {

    static let satispayPaymentIntentClientSecret = "pi_3PXrkJIFbdis1OxT0XLmWug3_secret_oZfKhPPuB4KNqR4H3f34ZgDvY"

    func _retrieveSatispayJSON(_ completion: @escaping ([AnyHashable: Any]?) -> Void) {
        let client = STPAPIClient(publishableKey: STPTestingITPublishableKey)
        client.retrievePaymentIntent(
            withClientSecret: Self.satispayPaymentIntentClientSecret,
            expand: ["payment_method"]
        ) { paymentIntent, _ in
            XCTAssertNotNil(paymentIntent?.paymentMethod?.allResponseFields["satispay"])
            let satispayJson = try? XCTUnwrap(paymentIntent?.paymentMethod?.satispay?.allResponseFields)
            completion(satispayJson)
        }
    }

    func testObjectDecoding() {
        let retrieveJSON = XCTestExpectation(description: "Retrieve JSON")

        _retrieveSatispayJSON({ json in
            let satispay = STPPaymentMethodSatispay.decodedObject(fromAPIResponse: json)
            XCTAssertNotNil(satispay, "Failed to decode JSON")
            retrieveJSON.fulfill()
        })

        wait(for: [retrieveJSON], timeout: STPTestingNetworkRequestTimeout)
    }
}
