//
//  STPEphemeralKeyTest.swift
//  Stripe
//
//  Created by Ben Guo on 5/17/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

@testable import Stripe

class STPEphemeralKeyTest: XCTestCase {
  func testDecoding() {
    let json = STPTestUtils.jsonNamed("EphemeralKey")!
    let key = STPEphemeralKey.decodedObject(fromAPIResponse: json)!
    XCTAssertEqual(key.stripeID, json["id"] as! String)
    XCTAssertEqual(key.secret, json["secret"] as! String)
    XCTAssertEqual(
      key.created,
      Date(timeIntervalSince1970: TimeInterval((json["created"] as! NSNumber).doubleValue)))
    XCTAssertEqual(
      key.expires,
      Date(timeIntervalSince1970: TimeInterval((json["expires"] as! NSNumber).doubleValue)))
    XCTAssertEqual(key.livemode, (json["livemode"] as! NSNumber).boolValue)
    XCTAssertEqual(key.customerID, "cus_123")
  }
}
