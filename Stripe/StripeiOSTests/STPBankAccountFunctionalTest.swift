//  Converted to Swift 5.8.1 by Swiftify v5.8.28463 - https://swiftify.com/
//
//  STPBankAccountFunctionalTest.m
//  Stripe
//
//  Created by Charles Scalesse on 10/2/14.
//
//

import StripeCoreTestUtils
import StripePaymentsTestUtils
import XCTest

class STPBankAccountFunctionalTest: STPNetworkStubbingTestCase {
    func testCreateAndRetreiveBankAccountToken() {
        let bankAccount = STPBankAccountParams()
        bankAccount.accountNumber = "000123456789"
        bankAccount.routingNumber = "110000000"
        bankAccount.country = "US"
        bankAccount.accountHolderName = "Jimmy bob"
        bankAccount.accountHolderType = STPBankAccountHolderType.company

        let client = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)

        let expectation = self.expectation(description: "Bank account creation")
        client.createToken(
            withBankAccount: bankAccount) { token, error in
            expectation.fulfill()
            XCTAssertNil(error, "error should be nil")
            XCTAssertNotNil(token, "token should not be nil")

            XCTAssertNotNil(token?.tokenId)
                XCTAssertEqual(token?.type, .bankAccount)
            XCTAssertNotNil(token?.bankAccount?.stripeID)
                XCTAssertEqual("STRIPE TEST BANK", token?.bankAccount?.bankName)
                XCTAssertEqual("6789", token?.bankAccount?.last4)
            XCTAssertEqual("Jimmy bob", token?.bankAccount?.accountHolderName)
            XCTAssertEqual(token?.bankAccount?.accountHolderType, STPBankAccountHolderType.company)
        }

        waitForExpectations(timeout: STPTestingNetworkRequestTimeout, handler: nil)
    }

    func testInvalidKey() {
        let bankAccount = STPBankAccountParams()
        bankAccount.accountNumber = "000123456789"
        bankAccount.routingNumber = "110000000"
        bankAccount.country = "US"

        let client = STPAPIClient(publishableKey: "not_a_valid_key_asdf")

        let expectation = self.expectation(description: "Bad bank account creation")

        client.createToken(
            withBankAccount: bankAccount) { token, error in
            expectation.fulfill()
            XCTAssertNil(token, "token should be nil")
            XCTAssertNotNil(error, "error should not be nil")
        }
        waitForExpectations(timeout: STPTestingNetworkRequestTimeout, handler: nil)
    }
}
