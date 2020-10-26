//
//  STPIntentActionTypeTest.swift
//  StripeiOS Tests
//
//  Created by Cameron Sabol on 9/29/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import XCTest

@testable import Stripe

class STPIntentActionTypeTest: XCTestCase {

  func testTypeFromString() {
    XCTAssertEqual(
      STPIntentActionType(string: "redirect_to_url"),
      STPIntentActionType.redirectToURL)
    XCTAssertEqual(
      STPIntentActionType(string: "REDIRECT_TO_URL"),
      STPIntentActionType.redirectToURL)

    XCTAssertEqual(
      STPIntentActionType(string: "use_stripe_sdk"),
      STPIntentActionType.useStripeSDK)
    XCTAssertEqual(
      STPIntentActionType(string: "USE_STRIPE_SDK"),
      STPIntentActionType.useStripeSDK)

    XCTAssertEqual(
      STPIntentActionType(string: "garbage"),
      STPIntentActionType.unknown)
    XCTAssertEqual(
      STPIntentActionType(string: "GARBAGE"),
      STPIntentActionType.unknown)
  }

}
