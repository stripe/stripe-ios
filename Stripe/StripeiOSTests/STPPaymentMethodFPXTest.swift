//  Converted to Swift 5.8.1 by Swiftify v5.8.28463 - https://swiftify.com/
//
//  STPPaymentMethodFPXTest.m
//  StripeiOS Tests
//
//  Created by David Estes on 8/26/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

class STPPaymentMethodFPXTest: XCTestCase {
    func exampleJson() -> [AnyHashable: Any]? {
        return [
            "bank": "maybank2u",
        ]
    }

    func testDecodedObjectFromAPIResponseRequiredFields() {
        let requiredFields: [String]? = []

        for field in requiredFields ?? [] {
            var response = exampleJson()
            response?.removeValue(forKey: field)

            XCTAssertNil(STPPaymentMethodFPX.decodedObject(fromAPIResponse: response))
        }

        XCTAssertNotNil(STPPaymentMethodFPX.decodedObject(fromAPIResponse: exampleJson()))
    }

    func testDecodedObjectFromAPIResponseMapping() {
        let response = exampleJson()
        let fpx = STPPaymentMethodFPX.decodedObject(fromAPIResponse: response)
        XCTAssertEqual(fpx?.bankIdentifierCode, "maybank2u")
    }
}
