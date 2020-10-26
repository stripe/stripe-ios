//
//  STPPinManagementFunctionalTest.m
//  StripeiOS Tests
//
//  Created by Arnaud Cavailhez on 4/29/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

import PassKit
import XCTest

@testable import Stripe

class TestEphemeralKeyProvider: NSObject, STPIssuingCardEphemeralKeyProvider {
  func createIssuingCardKey(
    withAPIVersion apiVersion: String,
    completion: STPJSONResponseCompletionBlock
  ) {
    print("apiVersion \(apiVersion)")
    let response =
      [
        "id": "ephkey_token",
        "object": "ephemeral_key",
        "associated_objects": [
          [
            "type": "issuing.card",
            "id": "ic_token",
          ]
        ],
        "created": NSNumber(value: 1_556_656_558),
        "expires": NSNumber(value: 1_556_660_158),
        "livemode": NSNumber(value: true),
        "secret": "ek_live_secret",
      ] as [String: Any]
    completion(response, nil)
  }
}

class STPPinManagementServiceFunctionalTest: STPNetworkStubbingTestCase {
  override func setUp() {
    //     self.recordingMode = YES;
    super.setUp()
  }

  func testRetrievePin() {
    let keyProvider = TestEphemeralKeyProvider()
    let service = STPPinManagementService(keyProvider: keyProvider)

    let expectation = self.expectation(description: "Received PIN")

    service.retrievePin(
      "ic_token",
      verificationId: "iv_token",
      oneTimeCode: "123456"
    ) { cardPin, status, error in
      if error == nil && status == .success && (cardPin?.pin == "2345") {
        expectation.fulfill()
      }
    }
    waitForExpectations(timeout: 5.0, handler: nil)
  }

  func testUpdatePin() {
    let keyProvider = TestEphemeralKeyProvider()
    let service = STPPinManagementService(keyProvider: keyProvider)

    let expectation = self.expectation(description: "Received PIN")

    service.updatePin(
      "ic_token",
      newPin: "3456",
      verificationId: "iv_token",
      oneTimeCode: "123-456"
    ) { cardPin, status, error in
      if error == nil && status == .success && (cardPin?.pin == "3456") {
        expectation.fulfill()
      }
    }
    waitForExpectations(timeout: 5.0, handler: nil)
  }

  func testRetrievePinWithError() {
    let keyProvider = TestEphemeralKeyProvider()
    let service = STPPinManagementService(keyProvider: keyProvider)

    let expectation = self.expectation(description: "Received Error")

    service.retrievePin(
      "ic_token",
      verificationId: "iv_token",
      oneTimeCode: "123456"
    ) { _, status, _ in
      if status == .errorVerificationAlreadyRedeemed {
        expectation.fulfill()
      }
    }
    waitForExpectations(timeout: 5.0, handler: nil)
  }
}
