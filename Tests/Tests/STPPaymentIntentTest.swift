//
//  STPPaymentIntentTest.swift
//  StripeiOS Tests
//
//  Created by Daniel Jackson on 6/27/18.
//  Copyright © 2018 Stripe, Inc. All rights reserved.
//

@testable import Stripe

class STPPaymentIntentTest: XCTestCase {
  func testIdentifierFromSecret() {
    XCTAssertEqual(
      STPPaymentIntent.id(fromClientSecret: "pi_123_secret_XYZ"),
      "pi_123")
    XCTAssertEqual(
      STPPaymentIntent.id(fromClientSecret: "pi_123_secret_RandomlyContains_secret_WhichIsFine"),
      "pi_123")

    XCTAssertNil(STPPaymentIntent.id(fromClientSecret: ""))
    XCTAssertNil(STPPaymentIntent.id(fromClientSecret: "po_123_secret_HasBadPrefix"))
    XCTAssertNil(STPPaymentIntent.id(fromClientSecret: "MissingSentinalForSplitting"))
  }

  // MARK: - Description Tests
  func testDescription() {
    let paymentIntent = STPFixtures.paymentIntent()

    XCTAssertNotNil(paymentIntent)
    let desc = paymentIntent!.description
    XCTAssertTrue(desc.contains(NSStringFromClass(type(of: paymentIntent!).self)))
    XCTAssertGreaterThan((desc.count), 500, "Custom description should be long")
  }

  // MARK: - STPAPIResponseDecodable Tests
  func testDecodedObjectFromAPIResponseRequiredFields() {
    let fullJson = STPTestUtils.jsonNamed(STPTestJSONPaymentIntent)

    XCTAssertNotNil(
      STPPaymentIntent.decodedObject(fromAPIResponse: fullJson), "can decode with full json")

    let requiredFields = ["id", "client_secret", "amount", "currency", "livemode", "status"]

    for field in requiredFields {
      var partialJson = fullJson

      XCTAssertNotNil(partialJson?[field])
      partialJson?.removeValue(forKey: field)

      XCTAssertNil(STPPaymentIntent.decodedObject(fromAPIResponse: partialJson))
    }
  }

  func testDecodedObjectFromAPIResponseMapping() {
    let response = STPTestUtils.jsonNamed("PaymentIntent")!
    let paymentIntent = STPPaymentIntent.decodedObject(fromAPIResponse: response)!

    XCTAssertEqual(paymentIntent.stripeId, "pi_1Cl15wIl4IdHmuTbCWrpJXN6")
    XCTAssertEqual(
      paymentIntent.clientSecret, "pi_1Cl15wIl4IdHmuTbCWrpJXN6_secret_EkKtQ7Sg75hLDFKqFG8DtWcaK")
    XCTAssertEqual(paymentIntent.amount, 2345)
    XCTAssertEqual(paymentIntent.canceledAt, Date(timeIntervalSince1970: 1_530_911_045))
    XCTAssertEqual(paymentIntent.captureMethod, .manual)
    XCTAssertEqual(paymentIntent.confirmationMethod, .automatic)
    XCTAssertEqual(paymentIntent.created, Date(timeIntervalSince1970: 1_530_911_040))
    XCTAssertEqual(paymentIntent.currency, "usd")
    XCTAssertEqual(paymentIntent.stripeDescription, "My Sample PaymentIntent")
    XCTAssertFalse(paymentIntent.livemode)
    XCTAssertEqual(paymentIntent.receiptEmail, "danj@example.com")

    // Deprecated: `nextSourceAction` & `authorizeWithURL` should just be aliases for `nextAction` & `redirectToURL`
    //#pragma clang diagnostic push
    //#pragma clang diagnostic ignored "-Wdeprecated"
    XCTAssertEqual(
      paymentIntent.nextSourceAction, paymentIntent.nextAction, "Should be the same object.")
    XCTAssertEqual(
      paymentIntent.nextSourceAction!.authorizeWithURL!, paymentIntent.nextAction!.redirectToURL,
      "Should be the same object.")
    //#pragma clang diagnostic pop

    // nextAction
    XCTAssertNotNil(paymentIntent.nextAction)
    XCTAssertEqual(paymentIntent.nextAction!.type, .redirectToURL)
    XCTAssertNotNil(paymentIntent.nextAction!.redirectToURL)
    XCTAssertNotNil(paymentIntent.nextAction!.redirectToURL!.url)
    let returnURL = paymentIntent.nextAction!.redirectToURL!.returnURL
    XCTAssertNotNil(returnURL)
    XCTAssertEqual(returnURL, URL(string: "payments-example://stripe-redirect"))
    let url = paymentIntent.nextAction!.redirectToURL!.url
    XCTAssertNotNil(url)

    XCTAssertEqual(
      url,
      URL(
        string:
          "https://hooks.stripe.com/redirect/authenticate/src_1Cl1AeIl4IdHmuTb1L7x083A?client_secret=src_client_secret_DBNwUe9qHteqJ8qQBwNWiigk"
      ))
    XCTAssertEqual(paymentIntent.sourceId, "src_1Cl1AdIl4IdHmuTbseiDWq6m")
    XCTAssertEqual(paymentIntent.status, .requiresAction)
    XCTAssertEqual(paymentIntent.setupFutureUsage, .none)

    XCTAssertEqual(
      paymentIntent.paymentMethodTypes, [NSNumber(value: STPPaymentMethodType.card.rawValue)])

    // lastPaymentError

    XCTAssertNotNil(paymentIntent.lastPaymentError)
    XCTAssertEqual(paymentIntent.lastPaymentError!.code, "payment_intent_authentication_failure")
    XCTAssertEqual(
      paymentIntent.lastPaymentError!.docURL,
      "https://stripe.com/docs/error-codes/payment-intent-authentication-failure")
    XCTAssertEqual(
      paymentIntent.lastPaymentError!.message,
      "The provided PaymentMethod has failed authentication. You can provide payment_method_data or a new PaymentMethod to attempt to fulfill this PaymentIntent again."
    )
    XCTAssertNotNil(paymentIntent.lastPaymentError!.paymentMethod)
    XCTAssertEqual(paymentIntent.lastPaymentError!.type, .invalidRequest)

    // Shipping
    XCTAssertNotNil(paymentIntent.shipping)
    XCTAssertEqual(paymentIntent.shipping!.carrier, "USPS")
    XCTAssertEqual(paymentIntent.shipping!.name, "Dan")
    XCTAssertEqual(paymentIntent.shipping!.phone, "1-415-555-1234")
    XCTAssertEqual(paymentIntent.shipping!.trackingNumber, "xyz123abc")
    XCTAssertNotNil(paymentIntent.shipping!.address)
    XCTAssertEqual(paymentIntent.shipping!.address!.city, "San Francisco")
    XCTAssertEqual(paymentIntent.shipping!.address!.country, "USA")
    XCTAssertEqual(paymentIntent.shipping!.address!.line1, "123 Main St")
    XCTAssertEqual(paymentIntent.shipping!.address!.line2, "Apt 456")
    XCTAssertEqual(paymentIntent.shipping!.address!.postalCode, "94107")
    XCTAssertEqual(paymentIntent.shipping!.address!.state, "CA")

    XCTAssertEqual(paymentIntent.allResponseFields as NSDictionary, response as NSDictionary)
  }
}
