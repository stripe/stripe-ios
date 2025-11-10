//
//  PassiveCaptchaTests.swift
//  StripePaymentsTests
//
//  Created by Joyce Qin on 8/21/25.
//

@_spi(STP) @testable import StripePayments
import XCTest

class PassiveCaptchaTests: XCTestCase {
    override func tearDown() {
        STPAnalyticsClient.sharedClient._testLogHistory = []
        super.tearDown()
    }

    struct TestDelayHCaptchaFactory: HCaptchaFactory {
        func create(siteKey: String, rqdata: String?) throws -> HCaptcha {
            let hcaptcha = try HCaptcha(apiKey: siteKey,
                                        passiveApiKey: true,
                                        rqdata: rqdata,
                                        host: "stripecdn.com")
            hcaptcha.manager.shouldDelayToken = true
            return hcaptcha
        }
    }

    func testPassiveCaptcha() async throws {
        // OCS mobile test key from https://dashboard.hcaptcha.com/sites/edit/143aadb6-fb60-4ab6-b128-f7fe53426d4a
        let siteKey = "143aadb6-fb60-4ab6-b128-f7fe53426d4a"
        let passiveCaptchaData = PassiveCaptchaData(siteKey: siteKey, rqdata: nil)
        let passiveCaptchaChallenge = PassiveCaptchaChallenge(passiveCaptchaData: passiveCaptchaData)
        await passiveCaptchaChallenge.setTimeout(timeout: 6)
        // wait to make sure that the token will be ready by the time we call fetchToken
        try await Task.sleep(nanoseconds: 6_000_000_000)
        let hcaptchaToken = await passiveCaptchaChallenge.fetchTokenWithTimeout()
        XCTAssertNotNil(hcaptchaToken)
        let passiveCaptchaEvents = STPAnalyticsClient.sharedClient._testLogHistory.map({ $0["event"] as? String }).filter({ $0?.starts(with: "elements.captcha.passive") ?? false })
        XCTAssertEqual(passiveCaptchaEvents, ["elements.captcha.passive.init", "elements.captcha.passive.execute", "elements.captcha.passive.success", "elements.captcha.passive.attach"])
        let successAnalytic = STPAnalyticsClient.sharedClient._testLogHistory.first(where: { $0["event"] as? String == "elements.captcha.passive.success" })
        XCTAssertEqual(successAnalytic?["site_key"] as? String, siteKey)
        let attachAnalytic = STPAnalyticsClient.sharedClient._testLogHistory.first(where: { $0["event"] as? String == "elements.captcha.passive.attach" })
        // should be ready
        XCTAssertEqual(attachAnalytic?["is_ready"] as? Bool, true)
    }

    func testPassiveCaptchaTimeout() async {
        let siteKey = "143aadb6-fb60-4ab6-b128-f7fe53426d4a"
        let passiveCaptchaData = PassiveCaptchaData(siteKey: siteKey, rqdata: nil)
        let passiveCaptchaChallenge = PassiveCaptchaChallenge(passiveCaptchaData: passiveCaptchaData, hcaptchaFactory: TestDelayHCaptchaFactory())
        await passiveCaptchaChallenge.setTimeout(timeout: 1)
        let hcaptchaToken = await passiveCaptchaChallenge.fetchTokenWithTimeout()
        // should return nil due to timeout
        XCTAssertNil(hcaptchaToken)
        let passiveCaptchaEvents = STPAnalyticsClient.sharedClient._testLogHistory.map({ $0["event"] as? String }).filter({ $0?.starts(with: "elements.captcha.passive") ?? false })
        XCTAssertEqual(passiveCaptchaEvents, ["elements.captcha.passive.init", "elements.captcha.passive.execute", "elements.captcha.passive.error"])
        let errorAnalytic = STPAnalyticsClient.sharedClient._testLogHistory.first(where: { $0["event"] as? String == "elements.captcha.passive.error" })
        XCTAssertEqual(errorAnalytic?["site_key"] as? String, siteKey)
        XCTAssertEqual(errorAnalytic?["error_type"] as? String, "StripeCore.TimeoutError")
        XCTAssertLessThan(errorAnalytic?["duration"] as! Double, 2000.0)
    }

    func testPassiveCaptchaLongTimeout() async {
        let siteKey = "143aadb6-fb60-4ab6-b128-f7fe53426d4a"
        let passiveCaptchaData = PassiveCaptchaData(siteKey: siteKey, rqdata: nil)
        let passiveCaptchaChallenge = PassiveCaptchaChallenge(passiveCaptchaData: passiveCaptchaData)
        await passiveCaptchaChallenge.setTimeout(timeout: 30)
        let startTime = Date()
        let hcaptchaToken = await passiveCaptchaChallenge.fetchTokenWithTimeout()
        // didn't time out because it finished early
        XCTAssertLessThan(Date().timeIntervalSince(startTime), 10)
        XCTAssertNotNil(hcaptchaToken)
    }
}
