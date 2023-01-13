//
//  STPIntentActionWeChatPayRedirectToAppTest.swift
//  StripeiOS Tests
//
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

@testable@_spi(STP) import Stripe
@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePayments
@testable@_spi(STP) import StripePaymentSheet
@testable@_spi(STP) import StripePaymentsUI

class STPIntentActionWeChatPayRedirectToAppTest: XCTestCase {
    func testActionNativeURL() throws {
        let testJSONString = """
            {
              "wechat_pay_redirect_to_ios_app": {
                "native_url": "weixin://app/value:wx12345a1234b1234c/pay/?package=Sign=WXPay&appid=wx12345a1234b1234c&partnerid=123456789&prepayid=wx12345a1234b1234c&noncestr=12345&timestamp=12345&sign=12341234",
              },
              "type": "wechat_pay_redirect_to_ios_app"
            }
            """
        guard
            let testJSONData = testJSONString.data(using: .utf8),
            let json = try? JSONSerialization.jsonObject(
                with: testJSONData,
                options: .allowFragments
            ) as? [AnyHashable: Any],
            let nextAction = STPIntentAction.decodedObject(fromAPIResponse: json),
            let weChatPayRedirectToApp = nextAction.weChatPayRedirectToApp
        else {
            XCTFail()
            return
        }
        XCTAssertEqual(
            weChatPayRedirectToApp.nativeURL,
            URL(
                string:
                    "weixin://app/value:wx12345a1234b1234c/pay/?package=Sign=WXPay&appid=wx12345a1234b1234c&partnerid=123456789&prepayid=wx12345a1234b1234c&noncestr=12345&timestamp=12345&sign=12341234"
            )
        )
    }
}
