//
//  STPPaymentMethodGiropayTests.swift
//  StripeiOS Tests
//
//  Created by Cameron Sabol on 4/21/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//
@testable import Stripe

class STPPaymentMethodGiropayTests: XCTestCase {
  private(set) var giropayJSON: [AnyHashable: Any]?

  func _retrieveGiropayDebitJSON(_ completion: @escaping ([AnyHashable: Any]?) -> Void) {
    if let giropayJSON = giropayJSON {
      completion(giropayJSON)
    } else {
      let client = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)
      client.retrievePaymentIntent(
        withClientSecret: "pi_1GfsdtFY0qyl6XeWLnepIXCI_secret_bLJRSeSY7fBjDXnwh9BUKilMW",
        expand: ["payment_method"]
      ) { [self] paymentIntent, _ in
        giropayJSON = paymentIntent?.paymentMethod?.giropay?.allResponseFields
        completion(giropayJSON ?? [:])
      }
    }
  }

  func testCorrectParsing() {
    let jsonExpectation = XCTestExpectation(description: "Fetch Giropay JSON")
    _retrieveGiropayDebitJSON({ json in
      let giropay = STPPaymentMethodGiropay.decodedObject(fromAPIResponse: json)
      XCTAssertNotNil(giropay, "Failed to decode JSON")
      jsonExpectation.fulfill()
    })
    wait(for: [jsonExpectation], timeout: STPTestingNetworkRequestTimeout)
  }
}
