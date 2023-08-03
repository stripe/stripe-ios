//  Converted to Swift 5.8.1 by Swiftify v5.8.28463 - https://swiftify.com/
//
//  STPCardFunctionalTest.swift
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

            XCTAssertNil(error)
            XCTAssertNotNil(Int(token ?? 0))

            XCTAssertNotNil(token?.tokenId ?? 0)
            XCTAssertEqual(token?.type ?? 0, Int(STPTokenTypeCard))
            XCTAssertEqual(6, token?.card.expMonth ?? 0)
            XCTAssertEqual(2024, token?.card.expYear ?? 0)
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

            XCTAssertNotNil(error)
            XCTAssertEqual((error as NSError?)?.code ?? 0, 70)
            XCTAssertEqual((error as NSError?)?.domain, STPError.stripeDomain())
            XCTAssertEqual((error as NSError?)?.userInfo[STPError.errorParameterKey()], "number")
            XCTAssertNil(Int(token ?? 0))
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

            XCTAssertNotNil(error)
            XCTAssertEqual((error as NSError?)?.code ?? 0, 70)
            XCTAssertEqual((error as NSError?)?.domain, STPError.stripeDomain())
            XCTAssertEqual((error as NSError?)?.userInfo[STPError.cardErrorCodeKey()], STPError.invalidExpYear())
            XCTAssertEqual((error as NSError?)?.userInfo[STPError.errorParameterKey()], "expYear")
            XCTAssertNil(Int(token ?? 0))
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
            XCTAssertNil(Int(token ?? 0))
            XCTAssertNotNil(error)
        }
        waitForExpectations(timeout: TestConstants.stpTestingNetworkRequestTimeout, handler: nil)
    }

    func testCreateCVCUpdateToken() {
        let client = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)

        let expectation = self.expectation(description: "CVC Update Token Creation")

        client.createToken(
            forCVCUpdate: "1234") { token, error in
            expectation.fulfill()

            XCTAssertNil(error)
            XCTAssertNotNil(Int(token ?? 0))

            XCTAssertNotNil(token?.tokenId ?? 0)
            XCTAssertEqual(token?.type ?? 0, Int(STPTokenTypeCvcUpdate))
        }
        waitForExpectations(timeout: TestConstants.stpTestingNetworkRequestTimeout, handler: nil)
    }

    func testInvalidCVC() {
        let client = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)

        let expectation = self.expectation(description: "Invalid CVC")

        client.createToken(
            forCVCUpdate: "1") { token, error in
            expectation.fulfill()

            XCTAssertNil(Int(token ?? 0))
            XCTAssertNotNil(error)
        }
        waitForExpectations(timeout: TestConstants.stpTestingNetworkRequestTimeout, handler: nil)
    }
}