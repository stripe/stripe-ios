//  Converted to Swift 5.8.1 by Swiftify v5.8.28463 - https://swiftify.com/
//
//  STPConnectAccountAddressTest.m
//  StripeiOS Tests
//
//  Created by Yuki Tokuhiro on 8/2/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

class STPConnectAccountAddressTest: XCTestCase {
    // MARK: STPFormEncodable Tests

    func testRootObjectName() {
        XCTAssertNil(STPConnectAccountAddress.rootObjectName())
    }

    func testPropertyNamesToFormFieldNamesMapping() {
        let address = STPConnectAccountAddress()

        let mapping = STPConnectAccountAddress.propertyNamesToFormFieldNamesMapping()

        for propertyName in mapping.keys {
            guard let propertyName = propertyName as? String else {
                continue
            }
            XCTAssertFalse(propertyName.contains(":"))
            XCTAssert(address.responds(to: NSSelectorFromString(propertyName)))
        }

        for formFieldName in mapping.values {
            guard let formFieldName = formFieldName as? String else {
                continue
            }
            XCTAssert((formFieldName is NSString))
            XCTAssert(formFieldName.count > 0)
        }

        XCTAssertEqual(mapping.values.count, Set(mapping.values).count)
    }
}
