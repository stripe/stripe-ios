//
//  STPIntentActionPromptPayDisplayQrCodeTest.swift
//  StripeiOSTests
//
//  Created by Nick Porter on 9/12/23.
//

import Foundation
@testable@_spi(STP) import Stripe

class STPIntentActionPromptPayDisplayQrCodeTest: XCTestCase {
    func testActionHostedUrl() throws {
        let testJSONString = """
            {
              "promptpay_display_qr_code": {
                "hosted_instructions_url": "stripe.com/test/promptpay/qr",
              },
              "type": "promptpay_display_qr_code"
            }
            """
        guard
            let testJSONData = testJSONString.data(using: .utf8),
            let json = try? JSONSerialization.jsonObject(
                with: testJSONData,
                options: .allowFragments
            ) as? [AnyHashable: Any],
            let nextAction = STPIntentAction.decodedObject(fromAPIResponse: json),
            let promptPayDisplayQrCode = nextAction.promptPayDisplayQrCode
        else {
            XCTFail()
            return
        }
        XCTAssertEqual(
            promptPayDisplayQrCode.hostedInstructionsURL,
            URL(string: "stripe.com/test/promptpay/qr")
        )
    }
}
