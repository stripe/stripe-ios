//
//  STPCardTest.swift
//  Stripe
//
//  Created by Saikat Chakrabarti on 11/5/12.
//
//

import XCTest

@testable import Stripe

class STPCardTest: XCTestCase {
  // MARK: - STPCardBrand Tests

  // These are only intended to be deprecated publicly.
  // When removed from public header, can remove these pragmas
  func testBrandFromString() {
    XCTAssertEqual(STPCard.brand(from: "visa"), .visa)
    XCTAssertEqual(STPCard.brand(from: "VISA"), .visa)

    XCTAssertEqual(STPCard.brand(from: "american express"), .amex)
    XCTAssertEqual(STPCard.brand(from: "AMERICAN EXPRESS"), .amex)

    XCTAssertEqual(STPCard.brand(from: "mastercard"), .mastercard)
    XCTAssertEqual(STPCard.brand(from: "MASTERCARD"), .mastercard)

    XCTAssertEqual(STPCard.brand(from: "discover"), .discover)
    XCTAssertEqual(STPCard.brand(from: "DISCOVER"), .discover)

    XCTAssertEqual(STPCard.brand(from: "jcb"), .JCB)
    XCTAssertEqual(STPCard.brand(from: "JCB"), .JCB)

    XCTAssertEqual(STPCard.brand(from: "diners club"), .dinersClub)
    XCTAssertEqual(STPCard.brand(from: "DINERS CLUB"), .dinersClub)

    XCTAssertEqual(STPCard.brand(from: "unionpay"), .unionPay)
    XCTAssertEqual(STPCard.brand(from: "UNIONPAY"), .unionPay)

    XCTAssertEqual(STPCard.brand(from: "unknown"), .unknown)
    XCTAssertEqual(STPCard.brand(from: "UNKNOWN"), .unknown)

    XCTAssertEqual(STPCard.brand(from: "garbage"), .unknown)
    XCTAssertEqual(STPCard.brand(from: "GARBAGE"), .unknown)
  }

  // MARK: - STPCardFundingType Tests

  //#pragma clang diagnostic push
  //#pragma clang diagnostic ignored "-Wdeprecated"
  // These are only intended to be deprecated publicly.
  // When removed from public header, can remove these pragmas
  func testFundingFromString() {
    XCTAssertEqual(STPCard.funding(from: "credit"), .credit)
    XCTAssertEqual(STPCard.funding(from: "CREDIT"), .credit)

    XCTAssertEqual(STPCard.funding(from: "debit"), .debit)
    XCTAssertEqual(STPCard.funding(from: "DEBIT"), .debit)

    XCTAssertEqual(STPCard.funding(from: "prepaid"), .prepaid)
    XCTAssertEqual(STPCard.funding(from: "PREPAID"), .prepaid)

    XCTAssertEqual(STPCard.funding(from: "other"), .other)
    XCTAssertEqual(STPCard.funding(from: "OTHER"), .other)

    XCTAssertEqual(STPCard.funding(from: "unknown"), .other)
    XCTAssertEqual(STPCard.funding(from: "UNKNOWN"), .other)

    XCTAssertEqual(STPCard.funding(from: "garbage"), .other)
    XCTAssertEqual(STPCard.funding(from: "GARBAGE"), .other)
  }

  //#pragma clang diagnostic pop
  func testStringFromFunding() {
    let values: [STPCardFundingType] = [
      .credit,
      .debit,
      .prepaid,
      .other,
    ]

    for funding in values {
      let string = STPCard.string(fromFunding: funding)

      switch funding {
      case .credit:
        XCTAssertEqual(string, "credit")
      case .debit:
        XCTAssertEqual(string, "debit")
      case .prepaid:
        XCTAssertEqual(string, "prepaid")
      case .other:
        XCTAssertNil(string)
      default:
        break
      }
    }
  }

  // MARK: -
  //#pragma clang diagnostic push
  //#pragma clang diagnostic ignored "-Wdeprecated"
  // These tests can ber removed in the future, they should be covered by
  // the equivalent response decodeable tests
  func testInitWithIDBrandLast4ExpMonthExpYearFunding() {
    let card = STPCard(
      id: "card_1AVRojEOD54MuFwSxr93QJSx",
      brand: .visa,
      last4: "5556",
      expMonth: 12,
      expYear: 2034,
      funding: .debit)
    XCTAssertEqual(card.stripeID, "card_1AVRojEOD54MuFwSxr93QJSx")
    XCTAssertEqual(card.brand, .visa)
    XCTAssertEqual(card.last4, "5556")
    XCTAssertEqual(card.expMonth, Int(12))
    XCTAssertEqual(card.expYear, Int(2034))
    XCTAssertEqual(card.funding, .debit)
  }

  //#pragma clang diagnostic pop
  func testIsApplePayCard() {
    let card = STPFixtures.card()

    card.allResponseFields = [:]
    XCTAssertFalse(card.isApplePayCard)

    card.allResponseFields = [
      "tokenization_method": "android_pay"
    ]
    XCTAssertFalse(card.isApplePayCard)

    card.allResponseFields = [
      "tokenization_method": "apple_pay"
    ]
    XCTAssertTrue(card.isApplePayCard)

    card.allResponseFields = [
      "tokenization_method": "garbage"
    ]
    XCTAssertFalse(card.isApplePayCard)

    card.allResponseFields = [
      "tokenization_method": ""
    ]
    XCTAssertFalse(card.isApplePayCard)

    // See: https://stripe.com/docs/api#card_object-tokenization_method
  }

  func testAddressPopulated() {
    let card = STPFixtures.card()
    XCTAssertEqual(card.address?.name, "Jane Austen")
    XCTAssertEqual(card.address?.line1, "123 Fake St")
    XCTAssertEqual(card.address?.line2, "Apt 1")
    XCTAssertEqual(card.address?.city, "Pittsburgh")
    XCTAssertEqual(card.address?.state, "PA")
    XCTAssertEqual(card.address?.postalCode, "19219")
    XCTAssertEqual(card.address?.country, "US")
  }

  // MARK: - Equality Tests
  func testCardEquals() {
    let card1 = STPFixtures.card()
    let card2 = STPFixtures.card()

    XCTAssertEqual(card1, card1)
    XCTAssertEqual(card1, card2)

    XCTAssertEqual(card1.hash, card1.hash)
    XCTAssertEqual(card1.hash, card2.hash)
  }

  // MARK: - STPAPIResponseDecodable Tests
  func testDecodedObjectFromAPIResponseRequiredFields() {
    let requiredFields = ["id", "last4", "brand", "exp_month", "exp_year"]

    for field in requiredFields {
      var response = STPTestUtils.jsonNamed("Card")
      response?.removeValue(forKey: field)

      XCTAssertNil(STPCard.decodedObject(fromAPIResponse: response))
    }

    XCTAssert((STPCard.decodedObject(fromAPIResponse: STPTestUtils.jsonNamed("Card")) != nil))
  }

  func testDecodedObjectFromAPIResponseMapping() {
    let response = STPTestUtils.jsonNamed("Card")!
    let card = STPCard.decodedObject(fromAPIResponse: response)!

    XCTAssertEqual(card.stripeID, "card_103kbR2eZvKYlo2CDczLmw4K")

    XCTAssertEqual(card.address?.city, "Pittsburgh")
    XCTAssertEqual(card.address?.country, "US")
    XCTAssertEqual(card.address?.line1, "123 Fake St")
    XCTAssertEqual(card.address?.line2, "Apt 1")
    XCTAssertEqual(card.address?.state, "PA")
    XCTAssertEqual(card.address?.postalCode, "19219")

    //#pragma clang diagnostic push
    //#pragma clang diagnostic ignored "-Wdeprecated"

    XCTAssertEqual(card.cardId, "card_103kbR2eZvKYlo2CDczLmw4K")

    XCTAssertEqual(card.addressCity, "Pittsburgh")
    XCTAssertEqual(card.addressCountry, "US")
    XCTAssertEqual(card.addressLine1, "123 Fake St")
    XCTAssertEqual(card.addressLine2, "Apt 1")
    XCTAssertEqual(card.addressState, "PA")
    XCTAssertEqual(card.addressZip, "19219")
    XCTAssertNil(card.metadata)

    //#pragma clang diagnostic pop

    XCTAssertEqual(card.brand, .visa)
    XCTAssertEqual(card.country, "US")
    XCTAssertEqual(card.currency, "usd")
    XCTAssertEqual(card.dynamicLast4, "5678")
    XCTAssertEqual(card.expMonth, Int(5))
    XCTAssertEqual(card.expYear, Int(2017))
    XCTAssertEqual(card.funding, .credit)
    XCTAssertEqual(card.last4, "4242")
    XCTAssertEqual(card.name, "Jane Austen")

    XCTAssertEqual(card.allResponseFields as NSDictionary, response as NSDictionary)
  }

  // MARK: - STPSourceProtocol Tests
  func testStripeID() {
    let card = STPFixtures.card()
    XCTAssertEqual(card.stripeID, "card_103kbR2eZvKYlo2CDczLmw4K")
  }

  // MARK: - STPPaymentOption Tests
  func testLabel() {
    let card = STPCard.decodedObject(fromAPIResponse: STPTestUtils.jsonNamed("Card"))!
    XCTAssertEqual(card.label, "Visa 4242")
  }

  // MARK: -
  func forEachBrand(_ block: @escaping (_ brand: STPCardBrand) -> Void) {
    let values: [STPCardBrand] = [
      .amex,
      .dinersClub,
      .discover,
      .JCB,
      .mastercard,
      .unionPay,
      .visa,
      .unknown,
    ]

    for brand in values {
      block(brand)
    }
  }
}
