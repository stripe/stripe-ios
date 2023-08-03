//  Converted to Swift 5.8.1 by Swiftify v5.8.28463 - https://swiftify.com/
//
//  STPCardFunctionalTest.m
//  Stripe
//
//  Created by Ray Morgan on 7/11/14.
//
//

import StripeCoreTestUtils
import XCTest

class STPCardFunctionalTest: XCTestCase {
    func testCreateCardToken() {
        let card = STPCardParams()

        card.number = "4242 4242 4242 4242"
        card.expMonth = 6
        card.expYear = 2024
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
            expectation.fulfill()

            XCTAssertNil(error, "error should be nil %@", error?.localizedDescription)
            XCTAssertNotNil(token, "token should not be nil")

            XCTAssertNotNil(token?.tokenId)
            XCTAssertEqual(token?.type, STPTokenTypeCard)
            XCTAssertEqual(6, token?.card.expMonth)
            XCTAssertEqual(2024, token?.card.expYear)
            XCTAssertEqual("4242", token?.card.last4)
            XCTAssertEqual("usd", token?.card.currency)
            XCTAssertEqual("10002", token?.card.address.postalCode)
        }
        waitForExpectations(timeout: TestConstants.stpTestingNetworkRequestTimeout, handler: nil)
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
            expectation.fulfill()

            XCTAssertNotNil(error, "error should not be nil")
            XCTAssertEqual((error as NSError?)?.code, 70)
            XCTAssertEqual((error as NSError?)?.domain, STPError.stripeDomain())
            XCTAssertEqual((error as NSError?)?.userInfo[STPError.errorParameterKey()], "number")
            XCTAssertNil(token, "token should be nil: %@", token?.description)
        }
        waitForExpectations(timeout: TestConstants.stpTestingNetworkRequestTimeout, handler: nil)
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
            expectation.fulfill()

            XCTAssertNotNil(error, "error should not be nil")
            XCTAssertEqual((error as NSError?)?.code, 70)
            XCTAssertEqual((error as NSError?)?.domain, STPError.stripeDomain())
            XCTAssertEqual((error as NSError?)?.userInfo[STPError.cardErrorCodeKey()], STPError.invalidExpYear())
            XCTAssertEqual((error as NSError?)?.userInfo[STPError.errorParameterKey()], "expYear")
            XCTAssertNil(token, "token should be nil: %@", token?.description)
        }
        waitForExpectations(timeout: TestConstants.stpTestingNetworkRequestTimeout, handler: nil)
    }

    func testInvalidKey() {
        let card = STPCardParams()

        card.number = "4242 4242 4242 4242"
        card.expMonth = 6
        card.expYear = 2024

        let client = STPAPIClient(publishableKey: "not_a_valid_key_asdf")

        let expectation = self.expectation(description: "Card failure")
        client.createToken(
            withCard: card) { token, error in
            expectation.fulfill()
            XCTAssertNil(token, "token should be nil")
            XCTAssertNotNil(error, "error should not be nil")
        }
        waitForExpectations(timeout: TestConstants.stpTestingNetworkRequestTimeout, handler: nil)
    }

    func testCreateCVCUpdateToken() {
        let client = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)

        let expectation = self.expectation(description: "CVC Update Token Creation")

        client.createToken(
            forCVCUpdate: "1234") { token, error in
            expectation.fulfill()

            XCTAssertNil(error, "error should be nil %@", error?.localizedDescription)
            XCTAssertNotNil(token, "token should not be nil")

            XCTAssertNotNil(token?.tokenId)
            XCTAssertEqual(token?.type, STPTokenTypeCvcUpdate, "token should be type CVC Update")
        }
        waitForExpectations(timeout: TestConstants.stpTestingNetworkRequestTimeout, handler: nil)
    }

    func testInvalidCVC() {
        let client = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)

        let expectation = self.expectation(description: "Invalid CVC")

        client.createToken(
            forCVCUpdate: "1") { token, error in
            expectation.fulfill()

            XCTAssertNil(token, "token should be nil")
            XCTAssertNotNil(error, "error should not be nil")
        }
        waitForExpectations(timeout: TestConstants.stpTestingNetworkRequestTimeout, handler: nil)
    }
}
