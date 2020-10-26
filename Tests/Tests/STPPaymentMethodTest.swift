//
//  STPPaymentMethodTest.swift
//  StripeiOS Tests
//
//  Created by Yuki Tokuhiro on 3/6/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//
@testable import Stripe

class STPPaymentMethodTest: XCTestCase {
  // MARK: - STPPaymentMethodType Tests
  func testTypeFromString() {
    XCTAssertEqual(STPPaymentMethod.type(from: "au_becs_debit"), STPPaymentMethodType.AUBECSDebit)
    XCTAssertEqual(STPPaymentMethod.type(from: "AU_BECS_DEBIT"), STPPaymentMethodType.AUBECSDebit)
    XCTAssertEqual(STPPaymentMethod.type(from: "BACS_DEBIT"), STPPaymentMethodType.bacsDebit)
    XCTAssertEqual(STPPaymentMethod.type(from: "bacs_debit"), STPPaymentMethodType.bacsDebit)
    XCTAssertEqual(STPPaymentMethod.type(from: "BACS_DEBIT"), STPPaymentMethodType.bacsDebit)
    XCTAssertEqual(STPPaymentMethod.type(from: "card"), STPPaymentMethodType.card)
    XCTAssertEqual(STPPaymentMethod.type(from: "CARD"), STPPaymentMethodType.card)
    XCTAssertEqual(STPPaymentMethod.type(from: "ideal"), STPPaymentMethodType.iDEAL)
    XCTAssertEqual(STPPaymentMethod.type(from: "IDEAL"), STPPaymentMethodType.iDEAL)
    XCTAssertEqual(STPPaymentMethod.type(from: "fpx"), STPPaymentMethodType.FPX)
    XCTAssertEqual(STPPaymentMethod.type(from: "FPX"), STPPaymentMethodType.FPX)
    XCTAssertEqual(STPPaymentMethod.type(from: "sepa_debit"), STPPaymentMethodType.SEPADebit)
    XCTAssertEqual(STPPaymentMethod.type(from: "SEPA_DEBIT"), STPPaymentMethodType.SEPADebit)
    XCTAssertEqual(STPPaymentMethod.type(from: "card_present"), STPPaymentMethodType.cardPresent)
    XCTAssertEqual(STPPaymentMethod.type(from: "CARD_PRESENT"), STPPaymentMethodType.cardPresent)
    XCTAssertEqual(STPPaymentMethod.type(from: "unknown_string"), STPPaymentMethodType.unknown)
  }

  func testTypesFromStrings() {
    let rawTypes = [
      "card",
      "ideal",
      "card_present",
      "fpx",
      "sepa_debit",
      "bacs_debit",
      "au_becs_debit",
    ]
    let expectedTypes: [STPPaymentMethodType] = [
      .card,
      .iDEAL,
      .cardPresent,
      .FPX,
      .SEPADebit,
      .bacsDebit,
      .AUBECSDebit,
    ]
    XCTAssertEqual(STPPaymentMethod.paymentMethodTypes(from: rawTypes), expectedTypes)
  }

  func testStringFromType() {
    let values: [STPPaymentMethodType] = [
      .card,
      .iDEAL,
      .cardPresent,
      .FPX,
      .SEPADebit,
      .bacsDebit,
      .AUBECSDebit,
      .oxxo,
      .alipay,
      .payPal,
      .giropay,
      .unknown,
    ]
    for type in values {
      let string = STPPaymentMethod.string(from: type)

      switch type {
      case .card:
        XCTAssertEqual(string, "card")
      case .iDEAL:
        XCTAssertEqual(string, "ideal")
      case .cardPresent:
        XCTAssertEqual(string, "card_present")
      case .FPX:
        XCTAssertEqual(string, "fpx")
      case .SEPADebit:
        XCTAssertEqual(string, "sepa_debit")
      case .bacsDebit:
        XCTAssertEqual(string, "bacs_debit")
      case .AUBECSDebit:
        XCTAssertEqual(string, "au_becs_debit")
      case .giropay:
        XCTAssertEqual(string, "giropay")
      case .przelewy24:
        XCTAssertEqual(string, "p24")
      case .bancontact:
        XCTAssertEqual(string, "bancontact")
      case .EPS:
        XCTAssertEqual(string, "eps")
      case .oxxo:
        XCTAssertEqual(string, "oxxo")
      case .sofort:
        XCTAssertEqual(string, "sofort")
      case .alipay:
        XCTAssertEqual(string, "alipay")
      case .payPal:
        XCTAssertEqual(string, "paypal")
      case .unknown:
        XCTAssertNil(string)
      case .grabPay:
        XCTAssertEqual(string, "grabpay")
      default:
        break
      }
    }
  }

  // MARK: - STPAPIResponseDecodable Tests
  func testDecodedObjectFromAPIResponseRequiredFields() {
    let fullJson = STPTestUtils.jsonNamed(STPTestJSONPaymentMethodCard)

    XCTAssertNotNil(
      STPPaymentMethod.decodedObject(fromAPIResponse: fullJson), "can decode with full json")

    let requiredFields = ["id"]

    for field in requiredFields {
      var partialJson = fullJson

      XCTAssertNotNil(partialJson?[field])
      partialJson?.removeValue(forKey: field)

      XCTAssertNil(STPPaymentIntent.decodedObject(fromAPIResponse: partialJson))
    }
  }

  func testDecodedObjectFromAPIResponseMapping() {
    let response = STPTestUtils.jsonNamed(STPTestJSONPaymentMethodCard)
    let paymentMethod = STPPaymentMethod.decodedObject(fromAPIResponse: response)
    XCTAssertEqual(paymentMethod?.stripeId, "pm_123456789")
    XCTAssertEqual(paymentMethod?.created, Date(timeIntervalSince1970: 123_456_789))
    XCTAssertEqual(paymentMethod?.liveMode, false)
    XCTAssertEqual(paymentMethod?.type, .card)
    XCTAssertNotNil(paymentMethod?.billingDetails)
    XCTAssertNotNil(paymentMethod?.card)
    XCTAssertNil(paymentMethod?.customerId)
    XCTAssertEqual(paymentMethod!.allResponseFields as NSDictionary, response! as NSDictionary)
  }
}
