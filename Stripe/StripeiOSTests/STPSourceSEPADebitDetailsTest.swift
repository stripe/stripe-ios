//  Converted to Swift 5.8.1 by Swiftify v5.8.28463 - https://swiftify.com/
//
//  STPSourceSEPADebitDetails.m
//  Stripe
//
//  Created by Joey Dong on 6/26/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

@testable import StripePayments
import XCTest

class STPSourceSEPADebitDetailsTest: XCTestCase {
    // MARK: - Description Tests

    func testDescription() {
        let sepaDebitDetails = STPSourceSEPADebitDetails.decodedObject(fromAPIResponse: STPTestUtils.jsonNamed("SEPADebitSource")["sepa_debit"] as? [AnyHashable: Any])
        XCTAssertNotNil(sepaDebitDetails?.description)
    }

    // MARK: - STPAPIResponseDecodable Tests

    func testDecodedObjectFromAPIResponseRequiredFields() {
        let requiredFields: [String]? = []

        for field in requiredFields ?? [] {
            var response = STPTestUtils.jsonNamed("SEPADebitSource")["sepa_debit"] as? [AnyHashable: Any]
            response?.removeValue(forKey: field)

            XCTAssertNil(STPSourceSEPADebitDetails.decodedObject(fromAPIResponse: response))
        }

        XCTAssertNotNil(STPSourceSEPADebitDetails.decodedObject(fromAPIResponse: STPTestUtils.jsonNamed("SEPADebitSource")["sepa_debit"] as? [AnyHashable: Any]))
    }

    func testDecodedObjectFromAPIResponseMapping() {
        let response = STPTestUtils.jsonNamed("SEPADebitSource")["sepa_debit"] as? [AnyHashable: Any]
        let sepaDebitDetails = STPSourceSEPADebitDetails.decodedObject(fromAPIResponse: response)

        XCTAssertEqual(sepaDebitDetails?.bankCode, "37040044")
        XCTAssertEqual(sepaDebitDetails?.country, "DE")
        XCTAssertEqual(sepaDebitDetails?.fingerprint, "NxdSyRegc9PsMkWy")
        XCTAssertEqual(sepaDebitDetails?.last4, "3001")
        XCTAssertEqual(sepaDebitDetails?.mandateReference, "NXDSYREGC9PSMKWY")
        XCTAssertEqual(sepaDebitDetails?.mandateURL, URL(string: "https://hooks.stripe.com/adapter/sepa_debit/file/src_18HgGjHNCLa1Vra6Y9TIP6tU/src_client_secret_XcBmS94nTg5o0xc9MSliSlDW"))

        XCTAssertEqual(sepaDebitDetails!.allResponseFields as NSDictionary, response! as NSDictionary)
    }
}
