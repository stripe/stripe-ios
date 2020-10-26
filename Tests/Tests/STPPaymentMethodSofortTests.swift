//
//  STPPaymentMethodSofortTests.swift
//  StripeiOS Tests
//
//  Created by David Estes on 8/7/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//
@testable import Stripe

class STPPaymentMethodSofortTests: XCTestCase {
  private(set) var sofortJSON: [AnyHashable: Any]?

  func _retrieveSofortJSON(_ completion: @escaping ([AnyHashable: Any]?) -> Void) {
    if let sofortJSON = sofortJSON {
      completion(sofortJSON)
    } else {
      let client = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)
      client.retrievePaymentIntent(
        withClientSecret: "pi_1HDdfSFY0qyl6XeWjk7ogYVV_secret_5ikjoct7F271A4Bp6t7HkHwUo",
        expand: ["payment_method"]
      ) { [self] paymentIntent, _ in
        sofortJSON = paymentIntent?.paymentMethod?.sofort?.allResponseFields
        completion(sofortJSON ?? [:])
      }
    }
  }

  func testCorrectParsing() {
    let jsonExpectation = XCTestExpectation(description: "Fetch Sofort JSON")
    _retrieveSofortJSON({ json in
      let sofort = STPPaymentMethodSofort.decodedObject(fromAPIResponse: json)
      XCTAssertNotNil(sofort, "Failed to decode JSON")
      jsonExpectation.fulfill()
    })
    wait(for: [jsonExpectation], timeout: STPTestingNetworkRequestTimeout)
  }
}
