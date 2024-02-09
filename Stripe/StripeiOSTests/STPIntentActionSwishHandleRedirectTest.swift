//
//  STPIntentActionSwishHandleRedirectTest.swift
//  StripeiOSTests
//
//  Created by Nick Porter on 2/8/24.
//

@testable@_spi(STP) import Stripe

class STPIntentActionSwishHandleRedirectTest: XCTestCase {
    func testActionHostedUrl() throws {
        let testJSONString = """
            {
              "swish_handle_redirect_or_display_qr_code": {
                "hosted_instructions_url": "stripe.com/test/swish/qr",
              },
              "type": "swish_handle_redirect_or_display_qr_code"
            }
            """
        guard
            let testJSONData = testJSONString.data(using: .utf8),
            let json = try? JSONSerialization.jsonObject(
                with: testJSONData,
                options: .allowFragments
            ) as? [AnyHashable: Any],
            let nextAction = STPIntentAction.decodedObject(fromAPIResponse: json),
            let swishHandleRedirect = nextAction.swishHandleRedirect
        else {
            XCTFail()
            return
        }
        XCTAssertEqual(
            swishHandleRedirect.hostedInstructionsURL,
            URL(string: "stripe.com/test/swish/qr")
        )
    }
}
