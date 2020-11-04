//
//  STPPaymentMethodBancontactTests.swift
//  StripeiOS Tests
//
//  Created by Vineet Shah on 4/29/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

@testable import Stripe

class STPPaymentMethodBancontactTests: XCTestCase {
  private(set) var bancontactJSON: [AnyHashable: Any]?

  func _retrieveBancontactJSON(_ completion: @escaping ([AnyHashable: Any]?) -> Void) {
    if let bancontactJSON = bancontactJSON {
      completion(bancontactJSON)
    } else {
      let client = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)
      client.retrievePaymentIntent(
        withClientSecret: "pi_1GdPnbFY0qyl6XeW8Ezvxe87_secret_Fxi2EZBQ0nInHumvvezcTRWF4",
        expand: ["payment_method"]
      ) { [self] paymentIntent, _ in
        bancontactJSON = paymentIntent?.paymentMethod?.bancontact?.allResponseFields
        completion(bancontactJSON ?? [:])
      }
    }
  }

  func testCorrectParsing() {
    let expectation = self.expectation(description: "Retrieve payment intent")
    _retrieveBancontactJSON({ json in
      let bancontact = STPPaymentMethodBancontact.decodedObject(fromAPIResponse: json)
      XCTAssertNotNil(bancontact, "Failed to decode JSON")
      expectation.fulfill()
    })
    waitForExpectations(timeout: STPTestingNetworkRequestTimeout, handler: nil)
  }
}
