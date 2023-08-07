//  Converted to Swift 5.8.1 by Swiftify v5.8.28463 - https://swiftify.com/
//
//  STPSourceOwnerTest.m
//  Stripe
//
//  Created by Joey Dong on 6/23/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

import XCTest

class STPSourceOwnerTest: XCTestCase {
    // MARK: - STPAPIResponseDecodable Tests

    func testDecodedObjectFromAPIResponseRequiredFields() {
        let requiredFields: [String]? = []

        for field in requiredFields ?? [] {
            var response = STPTestUtils.jsonNamed(STPTestJSONSource3DS)["owner"] as? [AnyHashable: Any]
            response?.removeValue(forKey: field)

            XCTAssertNil(STPSourceOwner.decodedObject(fromAPIResponse: response))
        }

        XCTAssertNotNil(STPSourceOwner.decodedObject(fromAPIResponse: STPTestUtils.jsonNamed(STPTestJSONSource3DS)["owner"] as? [AnyHashable: Any]))
    }

    func testDecodedObjectFromAPIResponseMapping() {
        guard
            let response = STPTestUtils.jsonNamed(STPTestJSONSource3DS)["owner"] as? NSDictionary,
            let owner = STPSourceOwner.decodedObject(fromAPIResponse: response as? [AnyHashable: Any]) else {
            XCTFail()
            return
        }

        XCTAssertEqual(owner.address?.city, "Pittsburgh")
        XCTAssertEqual(owner.address?.country, "US")
        XCTAssertEqual(owner.address?.line1, "123 Fake St")
        XCTAssertEqual(owner.address?.line2, "Apt 1")
        XCTAssertEqual(owner.address?.postalCode, "19219")
        XCTAssertEqual(owner.address?.state, "PA")
        XCTAssertEqual(owner.email, "jenny.rosen@example.com")
        XCTAssertEqual(owner.name, "Jenny Rosen")
        XCTAssertEqual(owner.phone, "555-867-5309")
        XCTAssertEqual(owner.verifiedAddress?.city, "Pittsburgh")
        XCTAssertEqual(owner.verifiedAddress?.country, "US")
        XCTAssertEqual(owner.verifiedAddress?.line1, "123 Fake St")
        XCTAssertEqual(owner.verifiedAddress?.line2, "Apt 1")
        XCTAssertEqual(owner.verifiedAddress?.postalCode, "19219")
        XCTAssertEqual(owner.verifiedAddress?.state, "PA")
        XCTAssertEqual(owner.verifiedEmail, "jenny.rosen@example.com")
        XCTAssertEqual(owner.verifiedName, "Jenny Rosen")
        XCTAssertEqual(owner.verifiedPhone, "555-867-5309")

        XCTAssertEqual(owner.allResponseFields as NSDictionary, response)
    }
}
