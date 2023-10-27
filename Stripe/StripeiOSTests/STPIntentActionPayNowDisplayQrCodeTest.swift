//
//  STPIntentActionPayNowDisplayQrCodeTest.swift
//  StripeiOSTests
//
//  Created by Nick Porter on 9/11/23.
//

@testable@_spi(STP) import Stripe

class STPIntentActionPayNowDisplayQrCodeTest: XCTestCase {
    func testActionHostedUrl() throws {
        let testJSONString = """
            {
              "paynow_display_qr_code": {
                "hosted_instructions_url": "stripe.com/test/paynow/qr",
              },
              "type": "paynow_display_qr_code"
            }
            """
        guard
            let testJSONData = testJSONString.data(using: .utf8),
            let json = try? JSONSerialization.jsonObject(
                with: testJSONData,
                options: .allowFragments
            ) as? [AnyHashable: Any],
            let nextAction = STPIntentAction.decodedObject(fromAPIResponse: json),
            let payNowDisplayQrCode = nextAction.payNowDisplayQrCode
        else {
            XCTFail()
            return
        }
        XCTAssertEqual(
            payNowDisplayQrCode.hostedInstructionsURL,
            URL(string: "stripe.com/test/paynow/qr")
        )
    }
}
