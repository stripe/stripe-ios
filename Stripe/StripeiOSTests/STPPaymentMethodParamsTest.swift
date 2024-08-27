//  Converted to Swift 5.8.1 by Swiftify v5.8.28463 - https://swiftify.com/
//
//  STPPaymentMethodParamsTest.m
//  StripeiOS Tests
//
//  Created by Yuki Tokuhiro on 3/7/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

class STPPaymentMethodParamsTest: XCTestCase {
    // MARK: STPFormEncodable Tests

    func testRootObjectName() {
        XCTAssertNil(STPPaymentMethodParams.rootObjectName())
    }

    func testPropertyNamesToFormFieldNamesMapping() {
        let params = STPPaymentMethodParams()

        let mapping = STPPaymentMethodParams.propertyNamesToFormFieldNamesMapping()

        for propertyName in mapping.keys {
            XCTAssertFalse(propertyName.contains(":"))
            XCTAssert(params.responds(to: NSSelectorFromString(propertyName)))
        }

        for formFieldName in mapping.values {
            XCTAssert(formFieldName.count > 0)
        }

        XCTAssertEqual(mapping.values.count, Set(mapping.values).count)
    }
}
