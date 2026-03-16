//
//  STPPaymentMethodPayByBankTests.swift
//  StripeiOSTests
//

@testable import Stripe
import StripeCoreTestUtils
import XCTest

class STPPaymentMethodPayByBankTests: XCTestCase {

    static let payByBankPaymentIntentClientSecret = "pi_3TBdzVGoesj9fw9Q02JPHHQc_secret_NDNsHku6A1x1TNaAfVA4rhU6d"

    func _retrievePayByBankJSON(_ completion: @escaping ([AnyHashable: Any]?) -> Void) {
        let client = STPAPIClient(publishableKey: STPTestingGBPublishableKey)
        client.retrievePaymentIntent(
            withClientSecret: Self.payByBankPaymentIntentClientSecret,
            expand: ["payment_method"]
        ) { paymentIntent, _ in
            XCTAssertNotNil(paymentIntent?.paymentMethod?.allResponseFields["pay_by_bank"])
            let payByBankJson = try? XCTUnwrap(paymentIntent?.paymentMethod?.payByBank?.allResponseFields)
            completion(payByBankJson)
        }
    }

    func testObjectDecoding() {
        let retrieveJSON = XCTestExpectation(description: "Retrieve JSON")

        _retrievePayByBankJSON({ json in
            let payByBank = STPPaymentMethodPayByBank.decodedObject(fromAPIResponse: json)
            XCTAssertNotNil(payByBank, "Failed to decode JSON")
            retrieveJSON.fulfill()
        })

        wait(for: [retrieveJSON], timeout: STPTestingNetworkRequestTimeout)
    }
}
