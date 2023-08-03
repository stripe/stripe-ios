//  Converted to Swift 5.8.1 by Swiftify v5.8.28463 - https://swiftify.com/
//
//  STPBankAccountFunctionalTest.swift
//  Stripe
//
//  Created by Charles Scalesse on 10/2/14.
//
//

import StripeCoreTestUtils
import XCTest

class STPBankAccountFunctionalTest: XCTestCase {
    func testCreateAndRetreiveBankAccountToken() {
        let bankAccount = STPBankAccountParams()
        bankAccount.accountNumber = "000123456789"
        bankAccount.routingNumber = "110000000"
        bankAccount.country = "US"
        bankAccount.accountHolderName = "Jimmy bob"
        bankAccount.accountHolderType = STPBankAccountHolderTypeCompany

        let client = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)

        let expectation = self.expectation(description: "Bank account creation")
        client.createToken(
            withBankAccount: bankAccount) { token, error in
            expectation.fulfill()
            XCTAssertNil(error)
            XCTAssertNotNil(Int(token ?? 0))

            XCTAssertNotNil(token?.tokenId ?? 0)
            XCTAssertEqual(token?.type ?? 0, Int(STPTokenTypeBankAccount))
            XCTAssertNotNil(token?.bankAccount.stripeID ?? 0)
            XCTAssertEqual("STRIPE TEST BANK", token?.bankAccount.bankName)
            XCTAssertEqual("6789", token?.bankAccount.last4)
            XCTAssertEqual("Jimmy bob", token?.bankAccount.accountHolderName)
            XCTAssertEqual(token?.bankAccount.accountHolderType ?? 0, Int(STPBankAccountHolderTypeCompany))
        }

        waitForExpectations(timeout: TestConstants.stpTestingNetworkRequestTimeout, handler: nil)
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
            XCTAssertNil(Int(token ?? 0))
            XCTAssertNotNil(error)
        }
        waitForExpectations(timeout: TestConstants.stpTestingNetworkRequestTimeout, handler: nil)
    }
}