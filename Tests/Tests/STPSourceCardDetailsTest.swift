//
//  STPSourceCardDetailsTest.swift
//  Stripe
//
//  Created by Joey Dong on 6/21/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

import XCTest

@testable import Stripe

class STPSourceCardDetailsTest: XCTestCase {
  // MARK: - STPSourceCard3DSecureStatus Tests
  func testThreeDSecureStatusFromString() {
    XCTAssertEqual(STPSourceCardDetails.threeDSecureStatus(from: "required"), .required)
    XCTAssertEqual(STPSourceCardDetails.threeDSecureStatus(from: "REQUIRED"), .required)

    XCTAssertEqual(STPSourceCardDetails.threeDSecureStatus(from: "optional"), .optional)
    XCTAssertEqual(STPSourceCardDetails.threeDSecureStatus(from: "OPTIONAL"), .optional)

    XCTAssertEqual(STPSourceCardDetails.threeDSecureStatus(from: "not_supported"), .notSupported)
    XCTAssertEqual(STPSourceCardDetails.threeDSecureStatus(from: "NOT_SUPPORTED"), .notSupported)

    XCTAssertEqual(STPSourceCardDetails.threeDSecureStatus(from: "recommended"), .recommended)
    XCTAssertEqual(STPSourceCardDetails.threeDSecureStatus(from: "RECOMMENDED"), .recommended)

    XCTAssertEqual(STPSourceCardDetails.threeDSecureStatus(from: "unknown"), .unknown)
    XCTAssertEqual(STPSourceCardDetails.threeDSecureStatus(from: "UNKNOWN"), .unknown)

    XCTAssertEqual(STPSourceCardDetails.threeDSecureStatus(from: "garbage"), .unknown)
    XCTAssertEqual(STPSourceCardDetails.threeDSecureStatus(from: "GARBAGE"), .unknown)
  }

  func testStringFromThreeDSecureStatus() {
    let values: [STPSourceCard3DSecureStatus] = [
      .required,
      .optional,
      .notSupported,
      .recommended,
      .unknown,
    ]

    for threeDSecureStatus in values {
      let string = STPSourceCardDetails.string(fromThreeDSecureStatus: threeDSecureStatus)

      switch threeDSecureStatus {
      case .required:
        XCTAssertEqual(string, "required")
      case .optional:
        XCTAssertEqual(string, "optional")
      case .notSupported:
        XCTAssertEqual(string, "not_supported")
      case .recommended:
        XCTAssertEqual(string, "recommended")
      case .unknown:
        XCTAssertNil(string)
      default:
        break
      }
    }
  }

  // MARK: - Description Tests
  func testDescription() {
    let cardDetails = STPSourceCardDetails.decodedObject(
      fromAPIResponse: STPTestUtils.jsonNamed("CardSource")!["card"] as? [AnyHashable: Any])
    XCTAssert(cardDetails?.description != nil)
  }

  // MARK: - STPAPIResponseDecodable Tests
  func testDecodedObjectFromAPIResponseRequiredFields() {
    let requiredFields: [String]? = []

    for field in requiredFields ?? [] {
      var response = STPTestUtils.jsonNamed("CardSource")?["card"] as? [AnyHashable: Any]
      response?.removeValue(forKey: field)

      XCTAssertNil(STPSourceCardDetails.decodedObject(fromAPIResponse: response))
    }

    XCTAssert(
      (STPSourceCardDetails.decodedObject(
        fromAPIResponse: STPTestUtils.jsonNamed("CardSource")!["card"] as? [AnyHashable: Any])
        != nil))
  }

  func testDecodedObjectFromAPIResponseMapping() {
    let response = STPTestUtils.jsonNamed("CardSource")?["card"] as? [AnyHashable: Any]
    let cardDetails = STPSourceCardDetails.decodedObject(fromAPIResponse: response)!

    XCTAssertEqual(cardDetails.brand, .visa)
    XCTAssertEqual(cardDetails.country, "US")
    XCTAssertEqual(cardDetails.expMonth, UInt(12))
    XCTAssertEqual(cardDetails.expYear, UInt(2034))
    XCTAssertEqual(cardDetails.funding, .debit)
    XCTAssertEqual(cardDetails.last4, "5556")
    XCTAssertEqual(cardDetails.threeDSecure, .notSupported)

    XCTAssertEqual(cardDetails.allResponseFields as NSDictionary, response! as NSDictionary)
  }
}
