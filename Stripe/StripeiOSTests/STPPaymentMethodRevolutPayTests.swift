//
//  STPPaymentMethodRevolutPayTests.swift
//  StripeiOSTests
//

@testable import Stripe
import StripeCoreTestUtils
import XCTest

class STPPaymentMethodRevolutPayTests: XCTestCase {

    static let revolutPayPaymentIntentClientSecret = "pi_3NqNtpGoesj9fw9Q0BtxFWyY_secret_JQt5EYOtXT0i5mN1Ti9aUtkq3"

    func _retrieveRevolutPayJSON(_ completion: @escaping ([AnyHashable: Any]?) -> Void) {
        let client = STPAPIClient(publishableKey: STPTestingGBPublishableKey)
        client.retrievePaymentIntent(
            withClientSecret: Self.revolutPayPaymentIntentClientSecret,
            expand: ["payment_method"]
        ) { paymentIntent, _ in
            XCTAssertNotNil(paymentIntent?.paymentMethod?.allResponseFields["revolut_pay"])
            let revolutPayJson = try? XCTUnwrap(paymentIntent?.paymentMethod?.revolutPay?.allResponseFields)
            completion(revolutPayJson)
        }
    }

    func testObjectDecoding() {
        let retrieveJSON = XCTestExpectation(description: "Retrieve JSON")

        _retrieveRevolutPayJSON({ json in
            let revolutPay = STPPaymentMethodRevolutPay.decodedObject(fromAPIResponse: json)
            XCTAssertNotNil(revolutPay, "Failed to decode JSON")
            retrieveJSON.fulfill()
        })

        wait(for: [retrieveJSON], timeout: STPTestingNetworkRequestTimeout)
    }

}
