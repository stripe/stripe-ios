//
//  STPIntentActionAlipayHandleRedirectTest.swift
//  StripeiOS Tests
//
//  Created by Yuki Tokuhiro on 12/2/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

@testable@_spi(STP) import Stripe
@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePayments
@testable@_spi(STP) import StripePaymentSheet
@testable@_spi(STP) import StripePaymentsUI

class STPIntentActionAlipayHandleRedirectTest: XCTestCase {
    func testMarlinReturnURL() throws {
        let testJSONString = """
            {
              "alipay_handle_redirect": {
                "native_url": "alipay://alipayclient/?%7B%22dataString%22%3A%22_input_charset=utf-8%26app_pay=Y%26currency=USD%26forex_biz=FP%26notify_url=https%253A%252F%252Fhooks.stripe.com%252Falipay%252Falipay%252Fhook%252REDACTED%252Fsrc_REDACTED%26out_trade_no=src_REDACTED%26partner=REDACTED%26payment_type=1%26product_code=NEW_WAP_OVERSEAS_SELLER%26return_url=https%253A%252F%252Fhooks.stripe.com%252Fadapter%252Falipay%252Fredirect%252Fcomplete%252Fsrc_REDACTED%252Fsrc_client_secret_REDACTED%26secondary_merchant_id=acct_REDACTED%26secondary_merchant_industry=5734%26secondary_merchant_name=Yuki-Test%26sendFormat=normal%26service=create_forex_trade_wap%26sign=REDACTED%26sign_type=MD5%26subject=Yuki-Test%26supplier=Yuki-Test%26timeout_rule=20m%26total_fee=1.00%26bizcontext=%7B%5C%22av%5C%22%3A%5C%221.0%5C%22%2C%5C%22ty%5C%22%3A%5C%22ios_lite%5C%22%2C%5C%22appkey%5C%22%3A%5C%22123456789%5C%22%2C%5C%22sv%5C%22%3A%5C%22h.a.3.2.5%5C%22%2C%5C%22an%5C%22%3A%5C%22com.stripe.CustomSDKExample%5C%22%7D%22%2C%22fromAppUrlScheme%22%3A%22payments-example%22%2C%22requestType%22%3A%22SafePay%22%7D",
                "return_url": "payments-example://safepay/",
                "url": "https://hooks.stripe.com/redirect/authenticate/src_REDACTED?client_secret=src_client_secret_REDACTED"
              },
              "type": "alipay_handle_redirect"
            }
            """
        guard
            let testJSONData = testJSONString.data(using: .utf8),
            let json = try? JSONSerialization.jsonObject(
                with: testJSONData,
                options: .allowFragments
            ) as? [AnyHashable: Any],
            let nextAction = STPIntentAction.decodedObject(fromAPIResponse: json),
            let alipayRedirect = nextAction.alipayHandleRedirect
        else {
            XCTFail()
            return
        }
        XCTAssertEqual(
            alipayRedirect.nativeURL,
            URL(
                string:
                    "alipay://alipayclient/?%7B%22dataString%22%3A%22_input_charset=utf-8%26app_pay=Y%26currency=USD%26forex_biz=FP%26notify_url=https%253A%252F%252Fhooks.stripe.com%252Falipay%252Falipay%252Fhook%252REDACTED%252Fsrc_REDACTED%26out_trade_no=src_REDACTED%26partner=REDACTED%26payment_type=1%26product_code=NEW_WAP_OVERSEAS_SELLER%26return_url=https%253A%252F%252Fhooks.stripe.com%252Fadapter%252Falipay%252Fredirect%252Fcomplete%252Fsrc_REDACTED%252Fsrc_client_secret_REDACTED%26secondary_merchant_id=acct_REDACTED%26secondary_merchant_industry=5734%26secondary_merchant_name=Yuki-Test%26sendFormat=normal%26service=create_forex_trade_wap%26sign=REDACTED%26sign_type=MD5%26subject=Yuki-Test%26supplier=Yuki-Test%26timeout_rule=20m%26total_fee=1.00%26bizcontext=%7B%5C%22av%5C%22%3A%5C%221.0%5C%22%2C%5C%22ty%5C%22%3A%5C%22ios_lite%5C%22%2C%5C%22appkey%5C%22%3A%5C%22123456789%5C%22%2C%5C%22sv%5C%22%3A%5C%22h.a.3.2.5%5C%22%2C%5C%22an%5C%22%3A%5C%22com.stripe.CustomSDKExample%5C%22%7D%22%2C%22fromAppUrlScheme%22%3A%22payments-example%22%2C%22requestType%22%3A%22SafePay%22%7D"
            )
        )
        XCTAssertEqual(alipayRedirect.returnURL, URL(string: "payments-example://safepay/"))
        XCTAssertEqual(
            alipayRedirect.marlinReturnURL,
            URL(
                string:
                    "https://hooks.stripe.com/adapter/alipay/redirect/complete/src_REDACTED/src_client_secret_REDACTED"
            )
        )
    }
}
