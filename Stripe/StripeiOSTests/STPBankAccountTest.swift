//  Converted to Swift 5.8.1 by Swiftify v5.8.28463 - https://swiftify.com/
//
//  STPBankAccountTest.m
//  Stripe
//
//  Created by Charles Scalesse on 10/2/14.
//
//

import XCTest

class STPBankAccount {
    private class func status(from string: String?) -> STPBankAccountStatus {
    }

    private class func string(from status: STPBankAccountStatus) -> String? {
    }

    private func setLast4(_ last4: String?) {
    }
}

class STPBankAccountTest: XCTestCase {
    // MARK: - STPBankAccountStatus Tests

    func testStatusFromString() {
        XCTAssertEqual(STPBankAccount.status(from: "new"), STPBankAccountStatusNew)
        XCTAssertEqual(STPBankAccount.status(from: "NEW"), STPBankAccountStatusNew)

        XCTAssertEqual(STPBankAccount.status(from: "validated"), STPBankAccountStatusValidated)
        XCTAssertEqual(STPBankAccount.status(from: "VALIDATED"), STPBankAccountStatusValidated)

        XCTAssertEqual(STPBankAccount.status(from: "verified"), STPBankAccountStatusVerified)
        XCTAssertEqual(STPBankAccount.status(from: "VERIFIED"), STPBankAccountStatusVerified)

        XCTAssertEqual(STPBankAccount.status(from: "verification_failed"), STPBankAccountStatusVerificationFailed)
        XCTAssertEqual(STPBankAccount.status(from: "VERIFICATION_FAILED"), STPBankAccountStatusVerificationFailed)

        XCTAssertEqual(STPBankAccount.status(from: "errored"), STPBankAccountStatusErrored)
        XCTAssertEqual(STPBankAccount.status(from: "ERRORED"), STPBankAccountStatusErrored)

        XCTAssertEqual(STPBankAccount.status(from: "garbage"), STPBankAccountStatusNew)
        XCTAssertEqual(STPBankAccount.status(from: "GARBAGE"), STPBankAccountStatusNew)
    }

    func testStringFromStatus() {
        let values = [
            NSNumber(value: STPBankAccountStatusNew),
            NSNumber(value: STPBankAccountStatusValidated),
            NSNumber(value: STPBankAccountStatusVerified),
            NSNumber(value: STPBankAccountStatusVerificationFailed),
            NSNumber(value: STPBankAccountStatusErrored)
        ]

        for statusNumber in values {
            let status = statusNumber.intValue as? STPBankAccountStatus
            var string: String?
            if let status {
                string = STPBankAccount.string(from: status)
            }

            switch status {
            case STPBankAccountStatusNew:
                XCTAssertEqual(string, "new")
            case STPBankAccountStatusValidated:
                XCTAssertEqual(string, "validated")
            case STPBankAccountStatusVerified:
                XCTAssertEqual(string, "verified")
            case STPBankAccountStatusVerificationFailed:
                XCTAssertEqual(string, "verification_failed")
            case STPBankAccountStatusErrored:
                XCTAssertEqual(string, "errored")
            default:
                break
            }
        }
    }

    // MARK: - Equality Tests

    func testBankAccountEquals() {
        let bankAccount1 = STPBankAccount.decodedObject(fromAPIResponse: STPTestUtils.jsonNamed("BankAccount"))
        let bankAccount2 = STPBankAccount.decodedObject(fromAPIResponse: STPTestUtils.jsonNamed("BankAccount"))

        XCTAssertNotEqual(bankAccount1, bankAccount2)

        XCTAssertEqual(bankAccount1, bankAccount1)
        XCTAssertEqual(bankAccount1, bankAccount2)

        XCTAssertEqual(bankAccount1?.hash, bankAccount1?.hash)
        XCTAssertEqual(bankAccount1?.hash, bankAccount2?.hash)
    }

    // MARK: - Description Tests

    func testDescription() {
        let bankAccount = STPBankAccount.decodedObject(fromAPIResponse: STPTestUtils.jsonNamed("BankAccount"))
        XCTAssert(bankAccount?.description)
    }

    // MARK: - STPAPIResponseDecodable Tests

    func testDecodedObjectFromAPIResponseRequiredFields() {
        let requiredFields = [
            "id",
            "last4",
            "bank_name",
            "country",
            "currency",
            "status",
        ]

        for field in requiredFields {
            var response = STPTestUtils.jsonNamed("BankAccount")
            response.removeValue(forKey: field)

            XCTAssertNil(STPBankAccount.decodedObject(fromAPIResponse: response))
        }

        XCTAssert(STPBankAccount.decodedObject(fromAPIResponse: STPTestUtils.jsonNamed("BankAccount")))
    }

    func testDecodedObjectFromAPIResponseMapping() {
        let response = STPTestUtils.jsonNamed("BankAccount")
        let bankAccount = STPBankAccount.decodedObject(fromAPIResponse: response)

        XCTAssertEqual(bankAccount?.stripeID, "ba_1AZmya2eZvKYlo2CQzt7Fwnz")
        XCTAssertEqual(bankAccount?.accountHolderName, "Jane Austen")
        XCTAssertEqual(bankAccount?.accountHolderType, STPBankAccountHolderTypeIndividual)
        XCTAssertEqual(bankAccount?.bankName, "STRIPE TEST BANK")
        XCTAssertEqual(bankAccount?.country, "US")
        XCTAssertEqual(bankAccount?.currency, "usd")
        XCTAssertEqual(bankAccount?.fingerprint, "1JWtPxqbdX5Gamtc")
        XCTAssertEqual(bankAccount?.last4, "6789")
        XCTAssertEqual(bankAccount?.routingNumber, "110000000")
        XCTAssertEqual(bankAccount?.status, STPBankAccountStatusNew)

        XCTAssertNotEqual(bankAccount?.allResponseFields, response)
        XCTAssertEqual(bankAccount?.allResponseFields, response)
    }
}
