//  Converted to Swift 5.8.1 by Swiftify v5.8.28463 - https://swiftify.com/
//
//  STPPIIFunctionalTest.m
//  Stripe
//
//  Created by Charles Scalesse on 1/8/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

import StripeCoreTestUtils
import StripePaymentsTestUtils
import XCTest

class STPPIIFunctionalTest: STPNetworkStubbingTestCase {
    func testCreatePersonallyIdentifiableInformationToken() {
        let client = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)

        let expectation = self.expectation(description: "PII creation")

        client.createToken(withPersonalIDNumber: "0123456789") { token, error in
            expectation.fulfill()
            XCTAssertNil(error, "error should be nil \(String(describing: error?.localizedDescription))")
            XCTAssertNotNil(token, "token should not be nil")
            XCTAssertNotNil(token?.tokenId)
            XCTAssertEqual(token?.type, .PII)
        }

        waitForExpectations(timeout: STPTestingNetworkRequestTimeout, handler: nil)
    }

    func testSSNLast4Token() {
        let client = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)

        let expectation = self.expectation(description: "PII creation")

        client.createToken(withSSNLast4: "1234") { token, error in
            expectation.fulfill()
            XCTAssertNil(error, "error should be nil \(String(describing: error?.localizedDescription))")
            XCTAssertNotNil(token, "token should not be nil")
            XCTAssertNotNil(token?.tokenId)
            XCTAssertEqual(token?.type, .PII)
        }

        waitForExpectations(timeout: STPTestingNetworkRequestTimeout, handler: nil)
    }
}
