//  Converted to Swift 5.8.1 by Swiftify v5.8.28463 - https://swiftify.com/
//
//  STPConnectAccountAddressTest.m
//  StripeiOS Tests
//
//  Created by Yuki Tokuhiro on 8/2/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

import StripePayments
import XCTest

class STPConnectAccountAddressTest: XCTestCase {
    // MARK: STPFormEncodable Tests

    func testRootObjectName() {
        XCTAssertNil(STPConnectAccountAddress.rootObjectName())
    }

    func testPropertyNamesToFormFieldNamesMapping() {
        let address = STPConnectAccountAddress()

        let mapping = STPConnectAccountAddress.propertyNamesToFormFieldNamesMapping()

        for keyPath in mapping.keys {
            XCTAssertNotNil((address as Any)[keyPath: keyPath], "\(keyPath) does not apply to \(type(of: address))")
        }

        for formFieldName in mapping.values {
            XCTAssert(!formFieldName.isEmpty)
        }

        XCTAssertEqual(mapping.values.count, Set(mapping.values).count)
    }
}
