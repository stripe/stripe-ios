//
//  STPPinManagementServiceFunctionalTest.swift
//  StripeiOS Tests
//
//  Created by Arnaud Cavailhez on 4/29/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

import PassKit
import XCTest

import OHHTTPStubs
import OHHTTPStubsSwift
@testable@_spi(STP) import Stripe
@testable@_spi(STP) import StripeCore
import StripeCoreTestUtils
@testable@_spi(STP) import StripePayments
@testable@_spi(STP) import StripePaymentSheet
@testable import StripePaymentsTestUtils
@testable@_spi(STP) import StripePaymentsUI

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
                    ],
                ],
                "created": NSNumber(value: 1_556_656_558),
                "expires": NSNumber(value: 1_556_660_158),
                "livemode": NSNumber(value: true),
                "secret": "ek_live_secret",
            ] as [String: Any]
        completion(response, nil)
    }
}

class STPPinManagementServiceFunctionalTest: APIStubbedTestCase {

    func testRetrievePin() {
        let keyProvider = TestEphemeralKeyProvider()
        let service = STPPinManagementService(keyProvider: keyProvider)

        let expectation = self.expectation(description: "Received PIN")

        stub { urlRequest in
            return urlRequest.url?.absoluteString.contains("/v1/issuing/cards/ic_token/pin") ?? false
        } response: { _ in
            let pinResponseJSON = """
                {
                  "pin" : "2345",
                  "object" : "issuing.card_pin",
                  "card" : {
                    "id" : "ic_token",
                    "last4" : "1234",
                    "livemode" : true,
                    "shipping" : null,
                    "metadata" : {

                    },
                    "brand" : "Visa",
                    "authorization_controls" : {
                      "max_approvals" : null,
                      "currency" : null,
                      "allowed_categories" : null,
                      "spending_limits" : null,
                      "blocked_categories" : null,
                      "max_amount" : null
                    },
                    "type" : "virtual",
                    "cardholder" : {
                      "id" : "ich_token",
                      "livemode" : true,
                      "phone_number" : "+1415",
                      "metadata" : {

                      },
                      "authorization_controls" : {
                        "blocked_categories" : [

                        ],
                        "spending_limits" : [

                        ],
                        "allowed_categories" : [

                        ]
                      },
                      "type" : "individual",
                      "object" : "issuing.cardholder",
                      "billing" : {
                        "address" : {
                          "state" : "CA",
                          "country" : "US",
                          "line2" : "123",
                          "city" : "San Francisco",
                          "line1" : "510 Townsend St",
                          "postal_code" : "94103"
                        },
                        "name" : "Arnaud Cavailhez"
                      },
                      "created" : 1536780742,
                      "is_default" : false,
                      "email" : "acavailhez@stripe.com",
                      "name" : "Arnaud Cavailhez",
                      "status" : "active"
                    },
                    "object" : "issuing.card",
                    "exp_month" : 9,
                    "exp_year" : 2021,
                    "created" : 1536781947,
                    "currency" : "usd",
                    "name" : "Arnaud Cavailhez",
                    "status" : "active"
                  }
                }
                """
            return HTTPStubsResponse(data: pinResponseJSON.data(using: .utf8)!, statusCode: 200, headers: nil)
        }

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

        stub { urlRequest in
            return urlRequest.url?.absoluteString.contains("/v1/issuing/cards/ic_token/pin") ?? false
        } response: { _ in
            let pinResponseJSON = """
                {
                  "pin" : "3456",
                  "object" : "issuing.card_pin",
                  "card" : {
                    "id" : "ic_token",
                    "last4" : "1234",
                    "livemode" : true,
                    "replacement_for" : null,
                    "metadata" : {

                    },
                    "brand" : "Visa",
                    "shipping" : null,
                    "authorization_controls" : {
                      "max_approvals" : null,
                      "currency" : null,
                      "allowed_categories" : null,
                      "spending_limits" : null,
                      "blocked_categories" : null,
                      "max_amount" : null
                    },
                    "replacement_reason" : null,
                    "type" : "virtual",
                    "cardholder" : {
                      "id" : "ich_token",
                      "livemode" : true,
                      "phone_number" : "+1415",
                      "metadata" : {

                      },
                      "authorization_controls" : {
                        "blocked_categories" : [

                        ],
                        "spending_limits" : [

                        ],
                        "allowed_categories" : [

                        ]
                      },
                      "type" : "individual",
                      "object" : "issuing.cardholder",
                      "billing" : {
                        "address" : {
                          "state" : "CA",
                          "country" : "US",
                          "line2" : "123",
                          "city" : "San Francisco",
                          "line1" : "510 Townsend St",
                          "postal_code" : "94103"
                        },
                        "name" : "Arnaud Cavailhez"
                      },
                      "created" : 1536780742,
                      "is_default" : false,
                      "email" : "acavailhez@stripe.com",
                      "name" : "Arnaud Cavailhez",
                      "status" : "active"
                    },
                    "object" : "issuing.card",
                    "exp_month" : 9,
                    "exp_year" : 2021,
                    "created" : 1536781947,
                    "currency" : "usd",
                    "name" : "Arnaud Cavailhez",
                    "status" : "active"
                  }
                }
                """
            return HTTPStubsResponse(data: pinResponseJSON.data(using: .utf8)!, statusCode: 200, headers: nil)
        }

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

        stub { urlRequest in
            return urlRequest.url?.absoluteString.contains("/v1/issuing/cards/ic_token/pin") ?? false
        } response: { _ in
            let pinResponseJSON = """
                {
                  "error" : {
                    "message" : "Verification challenge does not exist or is already redeemed",
                    "type" : "invalid_request_error",
                    "code" : "already_redeemed"
                  }
                }
                """
            return HTTPStubsResponse(data: pinResponseJSON.data(using: .utf8)!, statusCode: 400, headers: nil)
        }

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
