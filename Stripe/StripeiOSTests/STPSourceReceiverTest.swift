//  Converted to Swift 5.8.1 by Swiftify v5.8.28463 - https://swiftify.com/
//
//  STPSourceReceiverTest.m
//  Stripe
//
//  Created by Joey Dong on 6/26/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

import XCTest

class STPSourceReceiverTest: XCTestCase {
    // MARK: - Description Tests

    func testDescription() {
        let receiver = STPSourceReceiver.decodedObject(fromAPIResponse: STPTestUtils.jsonNamed(STPTestJSONSource3DS)["receiver"] as? [AnyHashable: Any])
        XCTAssertNotNil(receiver?.description)
    }

    // MARK: - STPAPIResponseDecodable Tests

    func testDecodedObjectFromAPIResponseRequiredFields() {
        let requiredFields = [
            "address",
        ]

        for field in requiredFields {
            var response = STPTestUtils.jsonNamed(STPTestJSONSource3DS)["receiver"] as? [AnyHashable: Any]
            response?.removeValue(forKey: field)

            XCTAssertNil(STPSourceReceiver.decodedObject(fromAPIResponse: response))
        }

        XCTAssertNotNil(STPSourceReceiver.decodedObject(fromAPIResponse: STPTestUtils.jsonNamed(STPTestJSONSource3DS)["receiver"] as? [AnyHashable: Any]))
    }

    func testDecodedObjectFromAPIResponseMapping() {
        let response = STPTestUtils.jsonNamed(STPTestJSONSource3DS)["receiver"] as? [AnyHashable: Any]
        let receiver = STPSourceReceiver.decodedObject(fromAPIResponse: response)

        XCTAssertEqual(receiver?.address, "test_1MBhWS3uv4ynCfQXF3xQjJkzFPukr4K56N")
        XCTAssertEqual(receiver?.amountCharged, NSNumber(value: 300))
        XCTAssertEqual(receiver?.amountReceived, NSNumber(value: 200))
        XCTAssertEqual(receiver?.amountReturned, NSNumber(value: 100))

        XCTAssertEqual(receiver!.allResponseFields as NSDictionary, response! as NSDictionary)
    }
}
