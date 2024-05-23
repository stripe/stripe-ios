//  Converted to Swift 5.8.1 by Swiftify v5.8.28463 - https://swiftify.com/
//
//  STPIntentActionTest.m
//  StripeiOS Tests
//
//  Created by Daniel Jackson on 11/7/18.
//  Copyright © 2018 Stripe, Inc. All rights reserved.
//

@_spi(STP) import StripePayments

class STPIntentActionTest: XCTestCase {
    func testDecodedObjectFromAPIResponseRedirectToURL() {

        let decode: (([AnyHashable: Any]?) -> STPIntentAction?) = { dict in
            return .decodedObject(fromAPIResponse: dict)
        }

        XCTAssertNil(decode(nil))
        XCTAssertNil(decode([:]))
        XCTAssertNil(
            decode([
                        "redirect_to_url": [
                        "url": "http://stripe.com"
                    ],
                    ]),
            "fails without type")

        let missingDetails = decode(
            [
                        "type": "redirect_to_url"
                    ])
        XCTAssertNotNil(missingDetails)
        XCTAssertEqual(
            missingDetails!.type,
            .unknown,
            "Type becomes unknown if the redirect_to_url details are missing")

        let badURL = decode(
            [
                        "type": "redirect_to_url",
                        "redirect_to_url": [
                        "url": "not a url"
                    ],
                    ])
        XCTAssertNotNil(badURL)
        XCTAssertEqual(
            badURL!.type,
            .unknown,
            "Type becomes unknown if the redirect_to_url details don't have a valid URL")

        let missingReturnURL = decode(
            [
                        "type": "redirect_to_url",
                        "redirect_to_url": [
                        "url": "https://stripe.com/"
                    ],
                    ])
        XCTAssertNotNil(missingReturnURL)
        XCTAssertEqual(
            missingReturnURL!.type,
            .redirectToURL,
            "Missing return_url won't prevent it from decoding")
        XCTAssertNotNil(missingReturnURL?.redirectToURL?.url)
        XCTAssertEqual(
            missingReturnURL?.redirectToURL?.url,
            URL(string: "https://stripe.com/"))
        XCTAssertNil(missingReturnURL?.redirectToURL?.returnURL)

        let badReturnURL = decode(
            [
                        "type": "redirect_to_url",
                        "redirect_to_url": [
                        "url": "https://stripe.com/",
                        "return_url": "not a url",
                    ],
                    ])
        XCTAssertNotNil(badReturnURL)
        XCTAssertEqual(
            badReturnURL!.type,
            .redirectToURL,
            "invalid return_url won't prevent it from decoding")
        XCTAssertNotNil(badReturnURL?.redirectToURL?.url)
        XCTAssertEqual(
            badReturnURL?.redirectToURL?.url,
            URL(string: "https://stripe.com/"))
        XCTAssertNil(badReturnURL?.redirectToURL?.returnURL)

        let complete = decode(
            [
                        "type": "redirect_to_url",
                        "redirect_to_url": [
                        "url": "https://stripe.com/",
                        "return_url": "my-app://payment-complete",
                    ],
                    ])
        XCTAssertNotNil(complete)
        XCTAssertEqual(complete?.type, .redirectToURL)
        XCTAssertNotNil(complete?.redirectToURL?.url)
        XCTAssertEqual(
            complete?.redirectToURL?.url,
            URL(string: "https://stripe.com/"))
        XCTAssertNotNil(complete?.redirectToURL?.returnURL)
        XCTAssertEqual(
            complete?.redirectToURL?.returnURL,
            URL(string: "my-app://payment-complete"))
        XCTAssertFalse(complete!.redirectToURL!.followRedirects)
        XCTAssertFalse(complete!.redirectToURL!.useWebAuthSession)

        let withFlags = decode(
            [
                        "type": "redirect_to_url",
                        "redirect_to_url": [
                        "url": "https://stripe.com/redirect?useWebAuthSession=true&followRedirectsInSDK=true",
                        "return_url": "my-app://payment-complete",
                    ],
                    ])
        XCTAssertNotNil(withFlags)
        XCTAssertEqual(withFlags?.type, .redirectToURL)
        XCTAssertNotNil(withFlags?.redirectToURL?.url)
        XCTAssertTrue(withFlags!.redirectToURL!.followRedirects)
        XCTAssertTrue(withFlags!.redirectToURL!.useWebAuthSession)

        // Don't observe flags on non-Stripe URLs
        let withNonStripeFlags = decode(
            [
                        "type": "redirect_to_url",
                        "redirect_to_url": [
                        "url": "https://example.com/redirect?useWebAuthSession=true&followRedirectsInSDK=true",
                        "return_url": "my-app://payment-complete",
                    ],
                    ])
        XCTAssertFalse(withNonStripeFlags!.redirectToURL!.followRedirects)
        XCTAssertFalse(withNonStripeFlags!.redirectToURL!.useWebAuthSession)
    }
}
