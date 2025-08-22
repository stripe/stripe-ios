//
//  PassiveCaptchaTests.swift
//  StripePaymentsTests
//
//  Created by Joyce Qin on 8/21/25.
//

@_spi(STP) @testable import StripePayments
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
        let shortTimeoutNs: UInt64 = 1_000_000 // 1ms
        let passiveCaptchaChallenge = PassiveCaptchaChallenge(passiveCaptcha: passiveCaptcha, testTimeout: shortTimeoutNs)
        let hcaptchaToken = await passiveCaptchaChallenge.fetchToken()
        XCTAssertNil(hcaptchaToken)
    }
}
