//  Converted to Swift 5.8.1 by Swiftify v5.8.28463 - https://swiftify.com/
//
//  STPPaymentMethodBacsDebitTest.m
//  StripeiOS Tests
//
//  Created by Yuki Tokuhiro on 1/28/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

class STPPaymentMethodBacsDebitTest: XCTestCase {
    // MARK: - STPAPIResponseDecodable Tests

    func testDecodedObjectFromAPIResponseRequiredFields() {
        let paymentMethodJSON = STPTestUtils.jsonNamed(STPTestJSONPaymentMethodBacsDebit)
        let requiredFields: [String]? = []

        for field in requiredFields ?? [] {
            var response = paymentMethodJSON?["bacs_debit"] as? [AnyHashable: Any]
            response?.removeValue(forKey: field)

            XCTAssertNil(STPPaymentMethodBacsDebit.decodedObject(fromAPIResponse: response))
        }

        let paymentMethod = STPPaymentMethod.decodedObject(fromAPIResponse: paymentMethodJSON)
        XCTAssertNotNil(paymentMethod)
        XCTAssertNotNil(paymentMethod?.bacsDebit)
    }

    func testDecodedObjectFromAPIResponseMapping() {
        let response = STPTestUtils.jsonNamed(STPTestJSONPaymentMethodBacsDebit)["bacs_debit"] as? [AnyHashable: Any]
        let bacs = STPPaymentMethodBacsDebit.decodedObject(fromAPIResponse: response)
        XCTAssertEqual(bacs?.fingerprint, "9eMbmctOrd8i7DYa")
        XCTAssertEqual(bacs?.last4, "2345")
        XCTAssertEqual(bacs?.sortCode, "108800")
    }
}
