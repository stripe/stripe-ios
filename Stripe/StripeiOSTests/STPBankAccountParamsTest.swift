//  Converted to Swift 5.8.1 by Swiftify v5.8.28463 - https://swiftify.com/
//
//  STPBankAccountParamsTest.m
//  Stripe
//
//  Created by Joey Dong on 6/19/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

import XCTest

class STPBankAccountParams {
    private func accountHolderTypeString() -> String? {
    }
}

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
        XCTAssertEqual(STPBankAccountParams.accountHolderType(fromString: "individual"), STPBankAccountHolderTypeIndividual)
        XCTAssertEqual(STPBankAccountParams.accountHolderType(fromString: "INDIVIDUAL"), STPBankAccountHolderTypeIndividual)

        XCTAssertEqual(STPBankAccountParams.accountHolderType(fromString: "company"), STPBankAccountHolderTypeCompany)
        XCTAssertEqual(STPBankAccountParams.accountHolderType(fromString: "COMPANY"), STPBankAccountHolderTypeCompany)

        XCTAssertEqual(STPBankAccountParams.accountHolderType(fromString: "garbage"), STPBankAccountHolderTypeIndividual)
        XCTAssertEqual(STPBankAccountParams.accountHolderType(fromString: "GARBAGE"), STPBankAccountHolderTypeIndividual)
    }

    func testStringFromAccountHolderType() {
        let values = [
            NSNumber(value: STPBankAccountHolderTypeIndividual),
            NSNumber(value: STPBankAccountHolderTypeCompany),
        ]

        for accountHolderTypeNumber in values {
            let accountHolderType = accountHolderTypeNumber.intValue as? STPBankAccountHolderType
            let string = STPBankAccountParams.string(from: accountHolderType)

            switch accountHolderType {
            case STPBankAccountHolderTypeIndividual:
                XCTAssertEqual(string, "individual")
            case STPBankAccountHolderTypeCompany:
                XCTAssertEqual(string, "company")
            default:
                break
            }
        }
    }

    // MARK: - Description Tests

    func testDescription() {
        let bankAccountParams = STPBankAccountParams()
        XCTAssert(bankAccountParams.description)
    }

    // MARK: - STPFormEncodable Tests

    func testRootObjectName() {
        XCTAssertEqual(STPBankAccountParams.rootObjectName(), "bank_account")
    }

    func testPropertyNamesToFormFieldNamesMapping() {
        let bankAccountParams = STPBankAccountParams()

        let mapping = STPBankAccountParams.propertyNamesToFormFieldNamesMapping()

        for propertyName in mapping.keys {
            guard let propertyName = propertyName as? String else {
                continue
            }
            XCTAssertFalse(propertyName.contains(":"))
            XCTAssert(bankAccountParams.responds(to: NSSelectorFromString(propertyName)))
        }

        for formFieldName in mapping.values {
            guard let formFieldName = formFieldName as? String else {
                continue
            }
            XCTAssert((formFieldName is NSString))
            XCTAssert(formFieldName.count > 0)
        }

        XCTAssertEqual(mapping.values.count, Set<AnyHashable>(mapping.values).count)
    }

    func testAccountHolderTypeString() {
        let bankAccountParams = STPBankAccountParams()

        bankAccountParams.accountHolderType = STPBankAccountHolderTypeIndividual
        XCTAssertEqual(bankAccountParams.accountHolderTypeString(), "individual")

        bankAccountParams.accountHolderType = STPBankAccountHolderTypeCompany
        XCTAssertEqual(bankAccountParams.accountHolderTypeString(), "company")
    }
}
