//
//  STPPaymentMethodCardTest.swift
//  StripeiOS Tests
//
//  Created by Yuki Tokuhiro on 3/6/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//
import StripeCoreTestUtils

@testable@_spi(STP) import Stripe
@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePayments
@testable@_spi(STP) import StripePaymentSheet
@testable@_spi(STP) import StripePaymentsUI

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
        let decoded = STPPaymentMethodCard.decodedObject(
            fromAPIResponse: json as? [AnyHashable: Any]
        )
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
        XCTAssertEqual(STPCard.brand(from: "visa"), .visa)
        XCTAssertEqual(STPCard.brand(from: "VISA"), .visa)

        XCTAssertEqual(STPCard.brand(from: "amex"), .amex)
        XCTAssertEqual(STPCard.brand(from: "AMEX"), .amex)
        XCTAssertEqual(STPCard.brand(from: "american_express"), .amex)
        XCTAssertEqual(STPCard.brand(from: "AMERICAN_EXPRESS"), .amex)

        XCTAssertEqual(STPCard.brand(from: "mastercard"), .mastercard)
        XCTAssertEqual(STPCard.brand(from: "MASTERCARD"), .mastercard)

        XCTAssertEqual(STPCard.brand(from: "discover"), .discover)
        XCTAssertEqual(STPCard.brand(from: "DISCOVER"), .discover)

        XCTAssertEqual(STPCard.brand(from: "jcb"), .JCB)
        XCTAssertEqual(STPCard.brand(from: "JCB"), .JCB)

        XCTAssertEqual(STPCard.brand(from: "diners"), .dinersClub)
        XCTAssertEqual(STPCard.brand(from: "DINERS"), .dinersClub)
        XCTAssertEqual(STPCard.brand(from: "diners_club"), .dinersClub)
        XCTAssertEqual(STPCard.brand(from: "DINERS_CLUB"), .dinersClub)

        XCTAssertEqual(STPCard.brand(from: "unionpay"), .unionPay)
        XCTAssertEqual(STPCard.brand(from: "UNIONPAY"), .unionPay)

        XCTAssertEqual(STPCard.brand(from: "unknown"), .unknown)
        XCTAssertEqual(STPCard.brand(from: "UNKNOWN"), .unknown)

        XCTAssertEqual(STPCard.brand(from: "garbage"), .unknown)
        XCTAssertEqual(STPCard.brand(from: "GARBAGE"), .unknown)
    }
}
