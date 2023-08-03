//  Converted to Swift 5.8.1 by Swiftify v5.8.28463 - https://swiftify.com/
//
//  STPBankAccountTest.m
//  Stripe
//
//  Created by Charles Scalesse on 10/2/14.
//
//

@testable import StripePayments
import XCTest

class STPBankAccountTest: XCTestCase {
    // MARK: - STPBankAccountStatus Tests

    func testStatusFromString() {
        XCTAssertEqual(STPBankAccount.status(from: "new"), STPBankAccountStatus.new)
        XCTAssertEqual(STPBankAccount.status(from: "NEW"), STPBankAccountStatus.new)

        XCTAssertEqual(STPBankAccount.status(from: "validated"), STPBankAccountStatus.validated)
        XCTAssertEqual(STPBankAccount.status(from: "VALIDATED"), STPBankAccountStatus.validated)

        XCTAssertEqual(STPBankAccount.status(from: "verified"), STPBankAccountStatus.verified)
        XCTAssertEqual(STPBankAccount.status(from: "VERIFIED"), STPBankAccountStatus.verified)

        XCTAssertEqual(STPBankAccount.status(from: "verification_failed"), STPBankAccountStatus.verificationFailed)
        XCTAssertEqual(STPBankAccount.status(from: "VERIFICATION_FAILED"), STPBankAccountStatus.verificationFailed)

        XCTAssertEqual(STPBankAccount.status(from: "errored"), STPBankAccountStatus.errored)
        XCTAssertEqual(STPBankAccount.status(from: "ERRORED"), STPBankAccountStatus.errored)

        XCTAssertEqual(STPBankAccount.status(from: "garbage"), STPBankAccountStatus.new)
        XCTAssertEqual(STPBankAccount.status(from: "GARBAGE"), STPBankAccountStatus.new)
    }

    func testStringFromStatus() {
        let values = [
            STPBankAccountStatus.new,
            STPBankAccountStatus.validated,
            STPBankAccountStatus.verified,
            STPBankAccountStatus.verificationFailed,
            STPBankAccountStatus.errored,
        ]

        for status in values {
            let string = STPBankAccount.string(from: status)

            switch status {
            case STPBankAccountStatus.new:
                XCTAssertEqual(string, "new")
            case STPBankAccountStatus.validated:
                XCTAssertEqual(string, "validated")
            case STPBankAccountStatus.verified:
                XCTAssertEqual(string, "verified")
            case STPBankAccountStatus.verificationFailed:
                XCTAssertEqual(string, "verification_failed")
            case STPBankAccountStatus.errored:
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

        XCTAssertEqual(bankAccount1, bankAccount1)
        XCTAssertEqual(bankAccount1, bankAccount2)

        XCTAssertEqual(bankAccount1?.hash, bankAccount1?.hash)
        XCTAssertEqual(bankAccount1?.hash, bankAccount2?.hash)
    }

    // MARK: - Description Tests

    func testDescription() {
        let bankAccount = STPBankAccount.decodedObject(fromAPIResponse: STPTestUtils.jsonNamed("BankAccount"))
        XCTAssertNotNil(bankAccount?.description)
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
            response!.removeValue(forKey: field)

            XCTAssertNil(STPBankAccount.decodedObject(fromAPIResponse: response))
        }

        XCTAssertNotNil(STPBankAccount.decodedObject(fromAPIResponse: STPTestUtils.jsonNamed("BankAccount")))
    }

    func testDecodedObjectFromAPIResponseMapping() {
        let response = STPTestUtils.jsonNamed("BankAccount")
        let bankAccount = STPBankAccount.decodedObject(fromAPIResponse: response)

        XCTAssertEqual(bankAccount?.stripeID, "ba_1AZmya2eZvKYlo2CQzt7Fwnz")
        XCTAssertEqual(bankAccount?.accountHolderName, "Jane Austen")
        XCTAssertEqual(bankAccount?.accountHolderType, .individual)
        XCTAssertEqual(bankAccount?.bankName, "STRIPE TEST BANK")
        XCTAssertEqual(bankAccount?.country, "US")
        XCTAssertEqual(bankAccount?.currency, "usd")
        XCTAssertEqual(bankAccount?.fingerprint, "1JWtPxqbdX5Gamtc")
        XCTAssertEqual(bankAccount?.last4, "6789")
        XCTAssertEqual(bankAccount?.routingNumber, "110000000")
        XCTAssertEqual(bankAccount?.status, STPBankAccountStatus.new)

        XCTAssertEqual(bankAccount!.allResponseFields as NSDictionary, response! as NSDictionary)
    }
}
