//  Converted to Swift 5.8.1 by Swiftify v5.8.28463 - https://swiftify.com/
//
//  STPCardFunctionalTest.m
//  Stripe
//
//  Created by Ray Morgan on 7/11/14.
//
//

import StripeCoreTestUtils
import StripePaymentsTestUtils
import XCTest

class STPCardFunctionalTest: STPNetworkStubbingTestCase {
    func testCreateCardToken() {
        let card = STPCardParams()

        card.number = "4242 4242 4242 4242"
        card.expMonth = 6
        card.expYear = 2050
        card.currency = "usd"
        card.address.line1 = "123 Fake Street"
        card.address.line2 = "Apartment 4"
        card.address.city = "New York"
        card.address.state = "NY"
        card.address.country = "USA"
        card.address.postalCode = "10002"

        let client = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)

        let expectation = self.expectation(description: "Card creation")

        client.createToken(
            withCard: card) { token, error in
            XCTAssertNil(error, "error should be nil")
            XCTAssertNotNil(token, "token should not be nil")

            XCTAssertNotNil(token?.tokenId)
                XCTAssertEqual(token?.type, .card)
            XCTAssertEqual(6, token?.card?.expMonth)
            XCTAssertEqual(2050, token?.card?.expYear)
            XCTAssertEqual("4242", token?.card?.last4)
            XCTAssertEqual("usd", token?.card?.currency)
            XCTAssertEqual("10002", token?.card?.address?.postalCode)
                expectation.fulfill()

        }
        waitForExpectations(timeout: STPTestingNetworkRequestTimeout, handler: nil)
    }

    func testCardTokenCreationWithInvalidParams() {
        let card = STPCardParams()

        card.number = "4242 4242 4242 4241"
        card.expMonth = 6
        card.expYear = 2024

        let client = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)

        let expectation = self.expectation(description: "Card creation")

        client.createToken(
            withCard: card) { token, error in
            XCTAssertNotNil(error, "error should not be nil")
            XCTAssertEqual((error as NSError?)?.code, 70)
            XCTAssertEqual((error as NSError?)?.domain, STPError.stripeDomain)
            XCTAssertEqual((error as NSError?)?.userInfo[STPError.errorParameterKey] as! String, "number")
            XCTAssertNil(token, "token should be nil")
            expectation.fulfill()
        }
        waitForExpectations(timeout: STPTestingNetworkRequestTimeout, handler: nil)
    }

    func testCardTokenCreationWithExpiredCard() {
        let card = STPCardParams()

        card.number = "4242 4242 4242 4242"
        card.expMonth = 6
        card.expYear = 2013

        let client = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)

        let expectation = self.expectation(description: "Card creation")

        client.createToken(
            withCard: card) { token, error in
            XCTAssertNotNil(error, "error should not be nil")
            XCTAssertEqual((error as NSError?)?.code, 70)
            XCTAssertEqual((error as NSError?)?.domain, STPError.stripeDomain    )
            XCTAssertEqual((error as NSError?)?.userInfo[STPError.cardErrorCodeKey] as! String, STPError.invalidExpYear)
            XCTAssertEqual((error as NSError?)?.userInfo[STPError.errorParameterKey] as! String, "expYear")
            XCTAssertNil(token, "token should be nil")
            expectation.fulfill()
        }
        waitForExpectations(timeout: STPTestingNetworkRequestTimeout, handler: nil)
    }

    func testInvalidKey() {
        let card = STPCardParams()

        card.number = "4242 4242 4242 4242"
        card.expMonth = 6
        card.expYear = 2050

        let client = STPAPIClient(publishableKey: "not_a_valid_key_asdf")

        let expectation = self.expectation(description: "Card failure")
        client.createToken(
            withCard: card) { token, error in
            XCTAssertNil(token, "token should be nil")
            XCTAssertNotNil(error, "error should not be nil")
            expectation.fulfill()
        }
        waitForExpectations(timeout: STPTestingNetworkRequestTimeout, handler: nil)
    }

    func testCreateCVCUpdateToken() {
        let client = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)

        let expectation = self.expectation(description: "CVC Update Token Creation")

        client.createToken(forCVCUpdate: "1234") { token, error in
            XCTAssertNil(error, "error should be nil")
            XCTAssertNotNil(token, "token should not be nil")

            XCTAssertNotNil(token?.tokenId)
            XCTAssertEqual(token?.type, .cvcUpdate, "token should be type CVC Update")
            expectation.fulfill()
        }
        waitForExpectations(timeout: STPTestingNetworkRequestTimeout, handler: nil)
    }

    func testInvalidCVC() {
        let client = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)

        let expectation = self.expectation(description: "Invalid CVC")

        client.createToken(
            forCVCUpdate: "1") { token, error in
            XCTAssertNil(token, "token should be nil")
            XCTAssertNotNil(error, "error should not be nil")
            expectation.fulfill()
        }
        waitForExpectations(timeout: STPTestingNetworkRequestTimeout, handler: nil)
    }
}
