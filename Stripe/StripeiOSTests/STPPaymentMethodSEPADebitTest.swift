//  Converted to Swift 5.8.1 by Swiftify v5.8.28463 - https://swiftify.com/
//
//  STPPaymentMethodSEPADebitTest.m
//  StripeiOS Tests
//
//  Created by Cameron Sabol on 10/7/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

class STPPaymentMethodSEPADebitTest: XCTestCase {
    // MARK: - STPAPIResponseDecodable Tests

    func testDecodedObjectFromAPIResponseRequiredFields() {
        let requiredFields: [String]? = []

        for field in requiredFields ?? [] {
            var response = STPTestUtils.jsonNamed("SEPADebitSource")["sepa_debit"] as? [AnyHashable: Any]
            response?.removeValue(forKey: field)

            XCTAssertNil(STPPaymentMethodSEPADebit.decodedObject(fromAPIResponse: response))
        }

        XCTAssertNotNil(STPPaymentMethodSEPADebit.decodedObject(fromAPIResponse: STPTestUtils.jsonNamed("SEPADebitSource")["sepa_debit"] as? [AnyHashable: Any]))
    }

    func testDecodedObjectFromAPIResponseMapping() {
        let response = STPTestUtils.jsonNamed("SEPADebitSource")["sepa_debit"] as? [AnyHashable: Any]
        let sepaDebit = STPPaymentMethodSEPADebit.decodedObject(fromAPIResponse: response)

        XCTAssertEqual(sepaDebit?.bankCode, "37040044")
        XCTAssertEqual(sepaDebit?.branchCode, "a_branch")
        XCTAssertEqual(sepaDebit?.country, "DE")
        XCTAssertEqual(sepaDebit?.fingerprint, "NxdSyRegc9PsMkWy")
        XCTAssertEqual(sepaDebit?.last4, "3001")
        XCTAssertEqual(sepaDebit?.mandate, "NXDSYREGC9PSMKWY")

        XCTAssertEqual(sepaDebit!.allResponseFields as NSDictionary, response! as NSDictionary)
    }
}
