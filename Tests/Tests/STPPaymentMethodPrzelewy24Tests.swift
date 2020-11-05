//
//  STPPaymentMethodPrzelewy24Tests.swift
//  StripeiOS Tests
//
//  Created by Vineet Shah on 4/23/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//
@testable import Stripe

class STPPaymentMethodPrzelewy24Tests: XCTestCase {
  private(set) var przelewy24JSON: [AnyHashable: Any]?

  func _retrievePrzelewy24JSON(_ completion: @escaping ([AnyHashable: Any]?) -> Void) {
    if let przelewy24JSON = przelewy24JSON {
      completion(przelewy24JSON)
    } else {
      let client = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)
      client.retrievePaymentIntent(
        withClientSecret: "pi_1GciHFFY0qyl6XeWp9RdhmFF_secret_rFeERcidL1O5o1lwQUcIjLEZz",
        expand: ["payment_method"]
      ) { [self] paymentIntent, _ in
        przelewy24JSON = paymentIntent?.paymentMethod?.przelewy24?.allResponseFields
        completion(przelewy24JSON ?? [:])
      }
    }
  }

  func testCorrectParsing() {
    let expectation = self.expectation(description: "Retrieve payment intent")
    _retrievePrzelewy24JSON({ json in
      let przelewy24 = STPPaymentMethodPrzelewy24.decodedObject(fromAPIResponse: json)
      XCTAssertNotNil(przelewy24, "Failed to decode JSON")
      expectation.fulfill()
    })
    waitForExpectations(timeout: STPTestingNetworkRequestTimeout, handler: nil)
  }
}
