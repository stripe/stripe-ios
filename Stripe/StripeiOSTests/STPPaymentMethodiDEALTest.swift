//  Converted to Swift 5.8.1 by Swiftify v5.8.28463 - https://swiftify.com/
//
//  STPPaymentMethodiDEALTest.m
//  StripeiOS Tests
//
//  Created by Yuki Tokuhiro on 3/9/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

class STPPaymentMethodiDEALTest: XCTestCase {
    func exampleJson() -> [AnyHashable: Any]? {
        return [
            "bank": "Rabobank",
            "bic": "RABONL2U",
        ]
    }

    func testDecodedObjectFromAPIResponseRequiredFields() {
        let requiredFields: [String]? = []

        for field in requiredFields ?? [] {
            var response = exampleJson()
            response?.removeValue(forKey: field)

            XCTAssertNil(STPPaymentMethodiDEAL.decodedObject(fromAPIResponse: response))
        }

        XCTAssertNotNil(STPPaymentMethodiDEAL.decodedObject(fromAPIResponse: exampleJson()))
    }

    func testDecodedObjectFromAPIResponseMapping() {
        let response = exampleJson()
        let ideal = STPPaymentMethodiDEAL.decodedObject(fromAPIResponse: response)
        XCTAssertEqual(ideal?.bankName, "Rabobank")
        XCTAssertEqual(ideal?.bankIdentifierCode, "RABONL2U")
    }
}
