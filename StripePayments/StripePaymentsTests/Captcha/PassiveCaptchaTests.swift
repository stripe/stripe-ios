//
//  PassiveCaptchaTests.swift
//  StripePaymentsTests
//
//  Created by Joyce Qin on 8/21/25.
//

@_spi(STP) @testable import StripePayments
@_spi(STP) @testable import StripePaymentSheet
import XCTest

class PassiveCaptchaTests: XCTestCase {
    func testPassiveCaptcha() async {
        // OCS mobile test key from https://dashboard.hcaptcha.com/sites/edit/143aadb6-fb60-4ab6-b128-f7fe53426d4a
        let passiveCaptcha = PassiveCaptcha(siteKey: "143aadb6-fb60-4ab6-b128-f7fe53426d4a", rqdata: nil)
        let timeoutNs: UInt64 = 6_000_000_000 // 6s
        let passiveCaptchaChallenge = PassiveCaptchaChallenge(passiveCaptcha: passiveCaptcha, testTimeout: timeoutNs)
        let hcaptchaToken = await passiveCaptchaChallenge.fetchToken()
        XCTAssertNotNil(hcaptchaToken)
    }

    func testPassiveCaptchaTimeout() async {
        let passiveCaptcha = PassiveCaptcha(siteKey: "143aadb6-fb60-4ab6-b128-f7fe53426d4a", rqdata: nil)
        let shortTimeoutNs: UInt64 = 0
        let passiveCaptchaChallenge = PassiveCaptchaChallenge(passiveCaptcha: passiveCaptcha, testTimeout: shortTimeoutNs)
        let hcaptchaToken = await passiveCaptchaChallenge.fetchToken()
        XCTAssertNil(hcaptchaToken)
    }

    func testFetchTokenForApplePayReturnsNil() async {
        let passiveCaptcha = PassiveCaptcha(siteKey: "143aadb6-fb60-4ab6-b128-f7fe53426d4a", rqdata: nil)
        let passiveCaptchaChallenge = PassiveCaptchaChallenge(passiveCaptcha: passiveCaptcha, testTimeout: 100_000_000)
        let paymentOption: PaymentOption = .applePay
        let token = await passiveCaptchaChallenge.fetchToken(for: paymentOption)
        XCTAssertNil(token, "ApplePay should not fetch captcha token")
    }

    func testFetchTokenForSavedPaymentMethodReturnsNil() async {
        let passiveCaptcha = PassiveCaptcha(siteKey: "143aadb6-fb60-4ab6-b128-f7fe53426d4a", rqdata: nil)
        let passiveCaptchaChallenge = PassiveCaptchaChallenge(passiveCaptcha: passiveCaptcha, testTimeout: 100_000_000)
        let _testCardJSON = [
            "id": "pm_123card",
            "type": "card",
            "card": [
                "last4": "4242",
                "brand": "visa",
                "fingerprint": "B8XXs2y2JsVBtB9f",
                "networks": ["available": ["visa"]],
                "exp_month": "01",
                "exp_year": "2040",
            ],
        ] as [AnyHashable: Any]
        let mockPaymentMethod = STPPaymentMethod.decodedObject(fromAPIResponse: _testCardJSON)!
        let paymentOption: PaymentOption = .saved(paymentMethod: mockPaymentMethod, confirmParams: nil)
        let token = await passiveCaptchaChallenge.fetchToken(for: paymentOption)
        XCTAssertNil(token, "Saved payment methods should not fetch captcha token")
    }

    func testFetchTokenForLinkWalletReturnsNil() async {
        let passiveCaptcha = PassiveCaptcha(siteKey: "143aadb6-fb60-4ab6-b128-f7fe53426d4a", rqdata: nil)
        let passiveCaptchaChallenge = PassiveCaptchaChallenge(passiveCaptcha: passiveCaptcha, testTimeout: 100_000_000)
        let paymentOption: PaymentOption = .link(option: .wallet)
        let token = await passiveCaptchaChallenge.fetchToken(for: paymentOption)
        XCTAssertNil(token, "Link wallet should not fetch captcha token")
    }

    func testFetchTokenForNewPaymentMethodCallsFetchToken() async {
        let passiveCaptcha = PassiveCaptcha(siteKey: "143aadb6-fb60-4ab6-b128-f7fe53426d4a", rqdata: nil)
        let passiveCaptchaChallenge = PassiveCaptchaChallenge(passiveCaptcha: passiveCaptcha, testTimeout: 6_000_000_000)
        await passiveCaptchaChallenge.start()
        let mockParams = IntentConfirmParams(type: .stripe(.card))
        let paymentOption: PaymentOption = .new(confirmParams: mockParams)
        let token = await passiveCaptchaChallenge.fetchToken(for: paymentOption)
        XCTAssertNotNil(token, "New payment method should fetch captcha token")
    }
}
