//  Converted to Swift 5.8.1 by Swiftify v5.8.28463 - https://swiftify.com/
//
//  STPConnectAccountFunctionalTest.m
//  StripeiOS Tests
//
//  Created by Daniel Jackson on 1/8/18.
//  Copyright © 2018 Stripe, Inc. All rights reserved.
//

import StripeCore
import StripeCoreTestUtils

class STPConnectAccountFunctionalTest: XCTestCase {
    /// Client with test publishable key
    var client: STPAPIClient!
    var individual: STPConnectAccountIndividualParams!
    var company: STPConnectAccountCompanyParams!

    override func setUp() {
        super.setUp()

        client = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)
        individual = STPConnectAccountIndividualParams()
        individual.firstName = "Test"
        var dob = DateComponents()
        dob.day = 31
        dob.month = 8
        dob.year = 2006
        individual.dateOfBirth = dob
        company = STPConnectAccountCompanyParams()
        company.name = "Test"
    }

    func testTokenCreation_terms_nil() {
        XCTAssertNil(
            STPConnectAccountParams(
                        tosShownAndAccepted: false,
                        individual: individual),
            "Guard to prevent trying to call this with `NO`")
        XCTAssertNil(
            STPConnectAccountParams(
                        tosShownAndAccepted: false,
                        company: company),
            "Guard to prevent trying to call this with `NO`")
    }

    func testTokenCreation_customer() {
        createToken(
            STPConnectAccountParams(company: company),
            shouldSucceed: true)
    }

    func testTokenCreation_company() {
        createToken(
            STPConnectAccountParams(individual: individual),
            shouldSucceed: true)
    }

    func testTokenCreation_empty_init() {
        createToken(STPConnectAccountParams(), shouldSucceed: true)

    }

    // MARK: -

    func createToken(_ params: STPConnectAccountParams?, shouldSucceed: Bool) {
        let expectation = self.expectation(description: "Connect Account Token")

        client.createToken(withConnectAccount: params!) { token, error in
            expectation.fulfill()

            if shouldSucceed {
                XCTAssertNil(error)
                XCTAssertNotNil(token)
                XCTAssertNotNil(token?.tokenId)
                XCTAssertEqual(token?.type, .account)
            } else {
                XCTAssertNil(token)
                XCTAssertNotNil(error)
            }
        }

        waitForExpectations(timeout: STPTestingNetworkRequestTimeout, handler: nil)
    }
}
