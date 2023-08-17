//  Converted to Swift 5.8.1 by Swiftify v5.8.28463 - https://swiftify.com/
//
//  STPConnectAccountParamsTest.m
//  StripeiOS Tests
//
//  Created by Daniel Jackson on 1/10/18.
//  Copyright © 2018 Stripe, Inc. All rights reserved.
//

@testable import StripePayments

class STPConnectAccountParamsTest: XCTestCase {
    // MARK: - STPFormEncodable Tests

    func testRootObjectName() {
        XCTAssertEqual(STPConnectAccountParams.rootObjectName(), "account")
    }

    func testBusinessType() {
        let individual = STPConnectAccountIndividualParams()
        let company = STPConnectAccountCompanyParams()

        XCTAssertEqual(STPConnectAccountParams(individual: individual).businessType, .individual)
        XCTAssertEqual(STPConnectAccountParams(tosShownAndAccepted: true, individual: individual)!.businessType, .individual)

        XCTAssertEqual(STPConnectAccountParams(company: company).businessType, .company)
        XCTAssertEqual(STPConnectAccountParams(tosShownAndAccepted: true, company: company)!.businessType, .company)
    }

    func testBusinessTypeString() {
        XCTAssertEqual("individual", STPConnectAccountParams.string(from: .individual))
        XCTAssertEqual("company", STPConnectAccountParams.string(from: .company))
        XCTAssertEqual(nil, STPConnectAccountParams.string(from: .none))
    }

    func testPropertyNamesToFormFieldNamesMapping() {
        let individual = STPConnectAccountIndividualParams()
        let accountParams = STPConnectAccountParams(individual: individual)

        let mapping = STPConnectAccountParams.propertyNamesToFormFieldNamesMapping()

        for propertyName in mapping.keys {
            XCTAssertFalse(propertyName.contains(":"))
            XCTAssert(accountParams.responds(to: NSSelectorFromString(propertyName)))
        }

        for formFieldName in mapping.values {
            XCTAssert(formFieldName.count > 0)
        }

        XCTAssertEqual(mapping.values.count, Set(mapping.values).count)
    }
}
