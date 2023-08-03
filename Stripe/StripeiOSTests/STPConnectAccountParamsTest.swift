//  Converted to Swift 5.8.1 by Swiftify v5.8.28463 - https://swiftify.com/
import Foundation
import XCTest

@testable@_spi(STP) import Stripe
@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePayments
@testable@_spi(STP) import StripePaymentSheet
@testable@_spi(STP) import StripePaymentsUI
//
//  STPConnectAccountParamsTest.swift
//  StripeiOS Tests
//
//  Created by Daniel Jackson on 1/10/18.
//  Copyright © 2018 Stripe, Inc. All rights reserved.
//

extension STPConnectAccountParams {
    class func string(from businessType: STPConnectAccountBusinessType) -> String? {
    }
}

class STPConnectAccountParamsTest: XCTestCase {
    // MARK: - STPFormEncodable Tests

    func testRootObjectName() {
        XCTAssertEqual(STPConnectAccountParams.rootObjectName(), "account")
    }

    func testBusinessType() {
        let individual = STPConnectAccountIndividualParams()
        let company = STPConnectAccountCompanyParams()

        XCTAssertEqual(STPConnectAccountParams(individual: individual).businessType, Int(STPConnectAccountBusinessTypeIndividual))
        XCTAssertEqual(STPConnectAccountParams(tosShownAndAccepted: true, individual: individual).businessType, Int(STPConnectAccountBusinessTypeIndividual))

        XCTAssertEqual(STPConnectAccountParams(company: company).businessType, Int(STPConnectAccountBusinessTypeCompany))
        XCTAssertEqual(STPConnectAccountParams(tosShownAndAccepted: true, company: company).businessType, Int(STPConnectAccountBusinessTypeCompany))
    }

    func testBusinessTypeString() {
        XCTAssertEqual("individual", STPConnectAccountParams.string(from: STPConnectAccountBusinessTypeIndividual))
        XCTAssertEqual("company", STPConnectAccountParams.string(from: STPConnectAccountBusinessTypeCompany))
    }

    func testPropertyNamesToFormFieldNamesMapping() {
        let individual = STPConnectAccountIndividualParams()
        let accountParams = STPConnectAccountParams(individual: individual)

        let mapping = STPConnectAccountParams.propertyNamesToFormFieldNamesMapping()

        for propertyName in mapping.keys {
            guard let propertyName = propertyName as? String else {
                continue
            }
            XCTAssertFalse(propertyName.contains(":"))
            XCTAssert(accountParams.responds(to: NSSelectorFromString(propertyName)))
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
}
