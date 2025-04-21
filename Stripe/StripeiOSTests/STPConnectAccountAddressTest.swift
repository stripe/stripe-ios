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
            XCTAssertFalse(propertyName.contains(":"))
            XCTAssert(address.responds(to: NSSelectorFromString(propertyName)))
        }

        for formFieldName in mapping.values {
            XCTAssert(!formFieldName.isEmpty)
        }

        XCTAssertEqual(mapping.values.count, Set(mapping.values).count)
    }
}
