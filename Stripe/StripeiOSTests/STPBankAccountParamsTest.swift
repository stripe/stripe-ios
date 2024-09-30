//  Converted to Swift 5.8.1 by Swiftify v5.8.28463 - https://swiftify.com/
//
//  STPBankAccountParamsTest.m
//  Stripe
//
//  Created by Joey Dong on 6/19/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

@testable import Stripe
@testable import StripePayments
import XCTest

class STPBankAccountParamsTest: XCTestCase {
    // MARK: -

    func testLast4ReturnsAccountNumberLast4() {
        let bankAccountParams = STPBankAccountParams()
        bankAccountParams.accountNumber = "000123456789"
        XCTAssertEqual(bankAccountParams.last4, "6789")
    }

    func testLast4ReturnsNilWhenNoAccountNumberSet() {
        let bankAccountParams = STPBankAccountParams()
        XCTAssertNil(bankAccountParams.last4)
    }

    func testLast4ReturnsNilWhenAccountNumberIsLessThanLength4() {
        let bankAccountParams = STPBankAccountParams()
        bankAccountParams.accountNumber = "123"
        XCTAssertNil(bankAccountParams.last4)
    }

    // MARK: - STPBankAccountHolderType Tests

    func testAccountHolderTypeFromString() {
        XCTAssertEqual(STPBankAccountParams.accountHolderType(from: "individual"), STPBankAccountHolderType.individual)
        XCTAssertEqual(STPBankAccountParams.accountHolderType(from: "INDIVIDUAL"), STPBankAccountHolderType.individual)

        XCTAssertEqual(STPBankAccountParams.accountHolderType(from: "company"), STPBankAccountHolderType.company)
        XCTAssertEqual(STPBankAccountParams.accountHolderType(from: "COMPANY"), STPBankAccountHolderType.company)

        XCTAssertEqual(STPBankAccountParams.accountHolderType(from: "garbage"), STPBankAccountHolderType.individual)
        XCTAssertEqual(STPBankAccountParams.accountHolderType(from: "GARBAGE"), STPBankAccountHolderType.individual)
    }

    func testStringFromAccountHolderType() {
        let values = [
            STPBankAccountHolderType.individual,
            STPBankAccountHolderType.company,
        ]

        for accountHolderType in values {
            let string = STPBankAccountParams.string(from: accountHolderType)

            switch accountHolderType {
            case STPBankAccountHolderType.individual:
                XCTAssertEqual(string, "individual")
            case STPBankAccountHolderType.company:
                XCTAssertEqual(string, "company")
            default:
                break
            }
        }
    }

    // MARK: - Description Tests

    func testDescription() {
        let bankAccountParams = STPBankAccountParams()
        XCTAssertNotNil(bankAccountParams.description)
    }

    // MARK: - STPFormEncodable Tests

    func testRootObjectName() {
        XCTAssertEqual(STPBankAccountParams.rootObjectName(), "bank_account")
    }

    func testPropertyNamesToFormFieldNamesMapping() {
        let bankAccountParams = STPBankAccountParams()

        let mapping = STPBankAccountParams.propertyNamesToFormFieldNamesMapping()

        for propertyName in mapping.keys {
            XCTAssertFalse(propertyName.contains(":"))
            XCTAssert(bankAccountParams.responds(to: NSSelectorFromString(propertyName)))
        }

        for formFieldName in mapping.values {
            XCTAssert(!formFieldName.isEmpty)
        }

        XCTAssertEqual(mapping.values.count, Set(mapping.values).count)
    }

    func testAccountHolderTypeString() {
        let bankAccountParams = STPBankAccountParams()

        bankAccountParams.accountHolderType = STPBankAccountHolderType.individual
        XCTAssertEqual(bankAccountParams.accountHolderTypeString(), "individual")

        bankAccountParams.accountHolderType = .company
        XCTAssertEqual(bankAccountParams.accountHolderTypeString(), "company")
    }
}
