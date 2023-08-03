//  Converted to Swift 5.8.1 by Swiftify v5.8.28463 - https://swiftify.com/
//
//  STPBankAccountTest.swift
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
        XCTAssertEqual(Int(STPBankAccount.status(from: "new")), Int(STPBankAccountStatusNew))
        XCTAssertEqual(Int(STPBankAccount.status(from: "NEW")), Int(STPBankAccountStatusNew))

        XCTAssertEqual(Int(STPBankAccount.status(from: "validated")), Int(STPBankAccountStatusValidated))
        XCTAssertEqual(Int(STPBankAccount.status(from: "VALIDATED")), Int(STPBankAccountStatusValidated))

        XCTAssertEqual(Int(STPBankAccount.status(from: "verified")), Int(STPBankAccountStatusVerified))
        XCTAssertEqual(Int(STPBankAccount.status(from: "VERIFIED")), Int(STPBankAccountStatusVerified))

        XCTAssertEqual(Int(STPBankAccount.status(from: "verification_failed")), Int(STPBankAccountStatusVerificationFailed))
        XCTAssertEqual(Int(STPBankAccount.status(from: "VERIFICATION_FAILED")), Int(STPBankAccountStatusVerificationFailed))

        XCTAssertEqual(Int(STPBankAccount.status(from: "errored")), Int(STPBankAccountStatusErrored))
        XCTAssertEqual(Int(STPBankAccount.status(from: "ERRORED")), Int(STPBankAccountStatusErrored))

        XCTAssertEqual(Int(STPBankAccount.status(from: "garbage")), Int(STPBankAccountStatusNew))
        XCTAssertEqual(Int(STPBankAccount.status(from: "GARBAGE")), Int(STPBankAccountStatusNew))
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

        XCTAssertEqual(bankAccount1?.hash ?? 0, bankAccount1?.hash ?? 0)
        XCTAssertEqual(bankAccount1?.hash ?? 0, bankAccount2?.hash ?? 0)
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
            response?.removeValue(forKey: field)

            XCTAssertNil(STPBankAccount.decodedObject(fromAPIResponse: response))
        }

        XCTAssert(STPBankAccount.decodedObject(fromAPIResponse: STPTestUtils.jsonNamed("BankAccount")))
    }

    func testDecodedObjectFromAPIResponseMapping() {
        let response = STPTestUtils.jsonNamed("BankAccount")
        let bankAccount = STPBankAccount.decodedObject(fromAPIResponse: response)

        XCTAssertEqual(bankAccount?.stripeID, "ba_1AZmya2eZvKYlo2CQzt7Fwnz")
        XCTAssertEqual(bankAccount?.accountHolderName, "Jane Austen")
        XCTAssertEqual(bankAccount?.accountHolderType ?? 0, Int(STPBankAccountHolderTypeIndividual))
        XCTAssertEqual(bankAccount?.bankName, "STRIPE TEST BANK")
        XCTAssertEqual(bankAccount?.country, "US")
        XCTAssertEqual(bankAccount?.currency, "usd")
        XCTAssertEqual(bankAccount?.fingerprint, "1JWtPxqbdX5Gamtc")
        XCTAssertEqual(bankAccount?.last4, "6789")
        XCTAssertEqual(bankAccount?.routingNumber, "110000000")
        XCTAssertEqual(bankAccount?.status ?? 0, Int(STPBankAccountStatusNew))

        XCTAssertNotEqual(bankAccount?.allResponseFields, response)
        XCTAssertEqual(bankAccount?.allResponseFields, response)
    }
}