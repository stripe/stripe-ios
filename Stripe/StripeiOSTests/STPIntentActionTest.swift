//  Converted to Swift 5.8.1 by Swiftify v5.8.28463 - https://swiftify.com/
import Foundation
import XCTest

@testable@_spi(STP) import Stripe
@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePayments
@testable@_spi(STP) import StripePaymentSheet
@testable@_spi(STP) import StripePaymentsUI
//
//  STPIntentActionTest.swift
//  StripeiOS Tests
//
//  Created by Daniel Jackson on 11/7/18.
//  Copyright © 2018 Stripe, Inc. All rights reserved.
//

class STPIntentActionTest: XCTestCase {
    func testDecodedObjectFromAPIResponseRedirectToURL() {

        let decode: (([AnyHashable : Any]?) -> STPIntentAction)? = { dict in
            return .decodedObject(fromAPIResponse: dict)
        }

        XCTAssertNil(Int(decode?(nil)))
        XCTAssertNil(Int(decode?([:])))
        XCTAssertNil(
            Int(decode?([
                "redirect_to_url": [
                "url": "http://stripe.com"
            ]
            ])))

        let missingDetails = decode?(
            [
                        "type": "redirect_to_url"
                    ])
        XCTAssertNotNil(Int(missingDetails))
        XCTAssertEqual(
            missingDetails.type,
            Int(STPIntentActionTypeUnknown))

        let badURL = decode?(
            [
                        "type": "redirect_to_url",
                        "redirect_to_url": [
                        "url": "not a url"
                    ]
                    ])
        XCTAssertNotNil(Int(badURL))
        XCTAssertEqual(
            badURL.type,
            Int(STPIntentActionTypeUnknown))

        let missingReturnURL = decode?(
            [
                        "type": "redirect_to_url",
                        "redirect_to_url": [
                        "url": "https://stripe.com/"
                    ]
                    ])
        XCTAssertNotNil(Int(missingReturnURL))
        XCTAssertEqual(
            missingReturnURL.type,
            Int(STPIntentActionTypeRedirectToURL))
        XCTAssertNotNil(missingReturnURL.redirectToURL.url)
        XCTAssertEqual(
            missingReturnURL.redirectToURL.url,
            URL(string: "https://stripe.com/"))
        XCTAssertNil(missingReturnURL.redirectToURL.returnURL)

        let badReturnURL = decode?(
            [
                        "type": "redirect_to_url",
                        "redirect_to_url": [
                        "url": "https://stripe.com/",
                        "return_url": "not a url"
                    ]
                    ])
        XCTAssertNotNil(Int(badReturnURL))
        XCTAssertEqual(
            badReturnURL.type,
            Int(STPIntentActionTypeRedirectToURL))
        XCTAssertNotNil(badReturnURL.redirectToURL.url)
        XCTAssertEqual(
            badReturnURL.redirectToURL.url,
            URL(string: "https://stripe.com/"))
        XCTAssertNil(badReturnURL.redirectToURL.returnURL)


        let complete = decode?(
            [
                        "type": "redirect_to_url",
                        "redirect_to_url": [
                        "url": "https://stripe.com/",
                        "return_url": "my-app://payment-complete"
                    ]
                    ])
        XCTAssertNotNil(Int(complete))
        XCTAssertEqual(complete.type, Int(STPIntentActionTypeRedirectToURL))
        XCTAssertNotNil(complete.redirectToURL.url)
        XCTAssertEqual(
            complete.redirectToURL.url,
            URL(string: "https://stripe.com/"))
        XCTAssertNotNil(complete.redirectToURL.returnURL)
        XCTAssertEqual(
            complete.redirectToURL.returnURL,
            URL(string: "my-app://payment-complete"))
    }
}
