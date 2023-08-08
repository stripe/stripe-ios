//  Converted to Swift 5.8.1 by Swiftify v5.8.28463 - https://swiftify.com/
//
//  STPConfirmCardOptionsTest.m
//  StripeiOS Tests
//
//  Created by Cameron Sabol on 1/10/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

class STPConfirmCardOptionsTest: XCTestCase {
    func testCVC() {
        let cardOptions = STPConfirmCardOptions()

        XCTAssertNil(cardOptions.cvc, "Initial/default value should be nil.")
        XCTAssertNil(cardOptions.network, "Initial/default value should be nil.")

        cardOptions.cvc = "123"
        XCTAssertEqual(cardOptions.cvc, "123")
        cardOptions.network = "visa"
        XCTAssertEqual(cardOptions.network, "visa")
    }

    func testEncoding() {
        let propertyMap = STPConfirmCardOptions.propertyNamesToFormFieldNamesMapping()
        let expected = [
            "cvc": "cvc",
            "network": "network",
        ]
        XCTAssertEqual(propertyMap, expected)
    }
}
