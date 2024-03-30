//  Converted to Swift 5.8.1 by Swiftify v5.8.28463 - https://swiftify.com/
//
//  STPPaymentMethodBillingDetailsTest.m
//  StripeiOS Tests
//
//  Created by Yuki Tokuhiro on 3/6/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

class STPPaymentMethodBillingDetailsTest: XCTestCase {
    // MARK: - STPAPIResponseDecodable Tests

    func testDecodedObjectFromAPIResponseRequiredFields() {
        let requiredFields: [String]? = []

        for field in requiredFields ?? [] {
            var response = STPTestUtils.jsonNamed(STPTestJSONPaymentMethodCard)["billing_details"] as? [AnyHashable: Any]
            response?.removeValue(forKey: field)

            XCTAssertNil(STPPaymentMethodBillingDetails.decodedObject(fromAPIResponse: response))
        }

        XCTAssertNotNil(STPPaymentMethodBillingDetails.decodedObject(fromAPIResponse: STPTestUtils.jsonNamed(STPTestJSONPaymentMethodCard)["billing_details"] as? [AnyHashable: Any]))
    }

    func testDecodedObjectFromAPIResponseMapping() {
        let response = STPTestUtils.jsonNamed(STPTestJSONPaymentMethodCard)["billing_details"] as? [AnyHashable: Any]
        let billingDetails = STPPaymentMethodBillingDetails.decodedObject(fromAPIResponse: response)
        XCTAssertEqual(billingDetails?.email, "jenny@example.com")
        XCTAssertEqual(billingDetails?.name, "jenny")
        XCTAssertEqual(billingDetails?.phone, "+15555555555")
        XCTAssertNotNil(billingDetails?.address)
    }
}
