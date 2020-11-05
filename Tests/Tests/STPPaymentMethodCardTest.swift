//
//  STPPaymentMethodCardTest.swift
//  StripeiOS Tests
//
//  Created by Yuki Tokuhiro on 3/6/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//
@testable import Stripe

private let kCardPaymentIntentClientSecret =
  "pi_1H5J4RFY0qyl6XeWFTpgue7g_secret_1SS59M0x65qWMaX2wEB03iwVE"

class STPPaymentMethodCardTest: XCTestCase {
  private(set) var cardJSON: [AnyHashable: Any]?

  func _retrieveCardJSON(_ completion: @escaping ([AnyHashable: Any]?) -> Void) {
    if let cardJSON = cardJSON {
      completion(cardJSON)
    } else {
      let client = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)
      client.retrievePaymentIntent(
        withClientSecret: kCardPaymentIntentClientSecret,
        expand: ["payment_method"]
      ) { [self] paymentIntent, _ in
        cardJSON = paymentIntent?.paymentMethod?.card?.allResponseFields
        completion(cardJSON ?? [:])
      }
    }
  }

  func testCorrectParsing() {
    let retrieveJSON = XCTestExpectation(description: "Retrieve JSON")
    _retrieveCardJSON({ json in
      let card = STPPaymentMethodCard.decodedObject(fromAPIResponse: json)
      XCTAssertNotNil(card, "Failed to decode JSON")
      retrieveJSON.fulfill()
      XCTAssertEqual(card?.brand, .visa)
      XCTAssertEqual(card?.country, "US")
      XCTAssertNotNil(card?.checks)
      XCTAssertEqual(card?.expMonth, 7)
      XCTAssertEqual(card?.expYear, 2021)
      XCTAssertEqual(card?.funding, "credit")
      XCTAssertEqual(card?.last4, "4242")
      XCTAssertNotNil(card?.threeDSecureUsage)
      XCTAssertEqual(card?.threeDSecureUsage?.supported, true)
      XCTAssertNotNil(card?.networks)
      XCTAssertEqual(card?.networks?.available, ["visa"])
      XCTAssertNil(card?.networks?.preferred)
    })
    wait(for: [retrieveJSON], timeout: STPTestingNetworkRequestTimeout)
  }

  func testDecodedObjectFromAPIResponseRequiredFields() {
    let requiredFields: [String]? = []

    for field in requiredFields ?? [] {
      var response =
        STPTestUtils.jsonNamed(STPTestJSONPaymentMethodCard)?["card"] as? [AnyHashable: Any]
      response?.removeValue(forKey: field)

      XCTAssertNil(STPPaymentMethodCard.decodedObject(fromAPIResponse: response))
    }
    let json = STPTestUtils.jsonNamed(STPTestJSONPaymentMethodCard)?["card"]
    let decoded = STPPaymentMethodCard.decodedObject(fromAPIResponse: json as? [AnyHashable: Any])
    XCTAssertNotNil(decoded)
  }

  func testDecodedObjectFromAPIResponseMapping() {
    let response =
      STPTestUtils.jsonNamed(STPTestJSONPaymentMethodCard)?["card"] as? [AnyHashable: Any]
    let card = STPPaymentMethodCard.decodedObject(fromAPIResponse: response)
    XCTAssertEqual(card?.brand, .visa)
    XCTAssertEqual(card?.country, "US")
    XCTAssertNotNil(card?.checks)
    XCTAssertEqual(card?.expMonth, 8)
    XCTAssertEqual(card?.expYear, 2020)
    XCTAssertEqual(card?.funding, "credit")
    XCTAssertEqual(card?.last4, "4242")
    XCTAssertEqual(card?.fingerprint, "6gVyxfIhqc8Z0g0X")
    XCTAssertNotNil(card?.threeDSecureUsage)
    XCTAssertEqual(card?.threeDSecureUsage?.supported, true)
    XCTAssertNotNil(card?.wallet)
  }

  func testBrandFromString() {
    XCTAssertEqual(STPPaymentMethodCard.brand(from: "visa"), .visa)
    XCTAssertEqual(STPPaymentMethodCard.brand(from: "VISA"), .visa)

    XCTAssertEqual(STPPaymentMethodCard.brand(from: "amex"), .amex)
    XCTAssertEqual(STPPaymentMethodCard.brand(from: "AMEX"), .amex)

    XCTAssertEqual(STPPaymentMethodCard.brand(from: "mastercard"), .mastercard)
    XCTAssertEqual(STPPaymentMethodCard.brand(from: "MASTERCARD"), .mastercard)

    XCTAssertEqual(STPPaymentMethodCard.brand(from: "discover"), .discover)
    XCTAssertEqual(STPPaymentMethodCard.brand(from: "DISCOVER"), .discover)

    XCTAssertEqual(STPPaymentMethodCard.brand(from: "jcb"), .JCB)
    XCTAssertEqual(STPPaymentMethodCard.brand(from: "JCB"), .JCB)

    XCTAssertEqual(STPPaymentMethodCard.brand(from: "diners"), .dinersClub)
    XCTAssertEqual(STPPaymentMethodCard.brand(from: "DINERS"), .dinersClub)

    XCTAssertEqual(STPPaymentMethodCard.brand(from: "unionpay"), .unionPay)
    XCTAssertEqual(STPPaymentMethodCard.brand(from: "UNIONPAY"), .unionPay)

    XCTAssertEqual(STPPaymentMethodCard.brand(from: "unknown"), .unknown)
    XCTAssertEqual(STPPaymentMethodCard.brand(from: "UNKNOWN"), .unknown)

    XCTAssertEqual(STPPaymentMethodCard.brand(from: "garbage"), .unknown)
    XCTAssertEqual(STPPaymentMethodCard.brand(from: "GARBAGE"), .unknown)
  }
}
