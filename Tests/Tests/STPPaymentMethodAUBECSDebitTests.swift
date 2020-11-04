//
//  STPPaymentMethodAUBECSDebitTests.swift
//  StripeiOS Tests
//
//  Created by Cameron Sabol on 3/4/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

@testable import Stripe

private var kAUBECSDebitPaymentIntentClientSecret =
  "pi_1GaRLjF7QokQdxByYgFPQEi0_secret_z76otRQH2jjOIEQYsA9vxhuKn"
class STPPaymentMethodAUBECSDebitTests: XCTestCase {
  private(set) var auBECSDebitJSON: [AnyHashable: Any]?

  func _retrieveAUBECSDebitJSON(_ completion: @escaping ([AnyHashable: Any]?) -> Void) {
    if let auBECSDebitJSON = auBECSDebitJSON {
      completion(auBECSDebitJSON)
    } else {
      let client = STPAPIClient(publishableKey: STPTestingAUPublishableKey)
      client.retrievePaymentIntent(
        withClientSecret: kAUBECSDebitPaymentIntentClientSecret,
        expand: ["payment_method"]
      ) { [self] paymentIntent, _ in
        auBECSDebitJSON = paymentIntent?.paymentMethod?.auBECSDebit?.allResponseFields
        completion(auBECSDebitJSON ?? [:])
      }
    }
  }

  func testCorrectParsing() {
    let retrieveJSON = XCTestExpectation(description: "Retrieve JSON")
    _retrieveAUBECSDebitJSON({ json in
      let auBECSDebit = STPPaymentMethodAUBECSDebit.decodedObject(fromAPIResponse: json)
      XCTAssertNotNil(auBECSDebit, "Failed to decode JSON")
      retrieveJSON.fulfill()
    })
    wait(for: [retrieveJSON], timeout: STPTestingNetworkRequestTimeout)
  }

  func testFailWithoutRequired() {
    var retrieveJSON = XCTestExpectation(description: "Retrieve JSON")
    _retrieveAUBECSDebitJSON({ json in
      var auBECSDebitJSON = json
      auBECSDebitJSON?["bsb_number"] = nil
      XCTAssertNil(
        STPPaymentMethodAUBECSDebit.decodedObject(fromAPIResponse: auBECSDebitJSON),
        "Should not intialize with missing `bsb_number`")
      retrieveJSON.fulfill()
    })
    wait(for: [retrieveJSON], timeout: STPTestingNetworkRequestTimeout)

    retrieveJSON = XCTestExpectation(description: "Retrieve JSON")
    _retrieveAUBECSDebitJSON({ json in
      var auBECSDebitJSON = json
      auBECSDebitJSON?["last4"] = nil
      XCTAssertNil(
        STPPaymentMethodAUBECSDebit.decodedObject(fromAPIResponse: auBECSDebitJSON),
        "Should not intialize with missing `last4`")
      retrieveJSON.fulfill()
    })
    wait(for: [retrieveJSON], timeout: STPTestingNetworkRequestTimeout)

    retrieveJSON = XCTestExpectation(description: "Retrieve JSON")
    _retrieveAUBECSDebitJSON({ json in
      var auBECSDebitJSON = json
      auBECSDebitJSON?["fingerprint"] = nil
      XCTAssertNil(
        STPPaymentMethodAUBECSDebit.decodedObject(fromAPIResponse: auBECSDebitJSON),
        "Should not intialize with missing `fingerprint`")
      retrieveJSON.fulfill()
    })
    wait(for: [retrieveJSON], timeout: STPTestingNetworkRequestTimeout)
  }
}
