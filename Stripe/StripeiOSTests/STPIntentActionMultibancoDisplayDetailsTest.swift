//
//  STPIntentActionMultibancoDisplayDetailsTest.swift
//  StripeiOSTests
//
//  Created by Nick Porter on 4/22/24.
//

import Foundation

class STPIntentActionMultibancoDisplayDetailsTest: XCTestCase {
    func testActionDisplayDetails() throws {
        let testJSONString = """
            {
              "multibanco_display_details": {
                "entity": "1234",
                "expires_at": 1714405124,
                "reference": "123456789",
                "hosted_voucher_url": "https://payments.stripe.com/multibanco/voucher"
              },
              "type": "multibanco_display_details"
            }
            """
        guard
            let testJSONData = testJSONString.data(using: .utf8),
            let json = try? JSONSerialization.jsonObject(
                with: testJSONData,
                options: .allowFragments
            ) as? [AnyHashable: Any],
            let nextAction = STPIntentAction.decodedObject(fromAPIResponse: json),
            let multibancoDisplayDetails = nextAction.multibancoDisplayDetails
        else {
            XCTFail()
            return
        }

        XCTAssertEqual(multibancoDisplayDetails.entity, "1234")
        XCTAssertEqual(multibancoDisplayDetails.expiresAt.timeIntervalSince1970, 1714405124)
        XCTAssertEqual(multibancoDisplayDetails.reference, "123456789")
        XCTAssertEqual(
            multibancoDisplayDetails.hostedVoucherURL,
            URL(string: "https://payments.stripe.com/multibanco/voucher")
        )
    }
}
