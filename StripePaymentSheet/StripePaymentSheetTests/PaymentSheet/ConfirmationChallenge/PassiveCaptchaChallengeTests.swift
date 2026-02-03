//
//  PassiveCaptchaChallengeTests.swift
//  StripePaymentSheetTests
//
//  Created by Joyce Qin on 8/21/25.
//

@_spi(STP) @testable import StripePayments
@_spi(STP) @testable import StripePaymentSheet
import XCTest

class PassiveCaptchaChallengeTests: XCTestCase {
    var window: UIWindow?

    override func setUp() {
        super.setUp()
        // Create a key window for HCaptcha WebView to initialize properly
        let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        if let windowScene = windowScene {
            window = UIWindow(windowScene: windowScene)
        } else {
            window = UIWindow(frame: UIScreen.main.bounds)
        }
        window?.rootViewController = UIViewController()
        window?.makeKeyAndVisible()
    }

    override func tearDown() {
        STPAnalyticsClient.sharedClient._testLogHistory = []
        window?.isHidden = true
        window = nil
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

    // OCS mobile test key from https://dashboard.hcaptcha.com/sites/edit/143aadb6-fb60-4ab6-b128-f7fe53426d4a
    let siteKey = "143aadb6-fb60-4ab6-b128-f7fe53426d4a"

    func testPassiveCaptcha() async throws {
        let passiveCaptchaData = PassiveCaptchaData(siteKey: siteKey, rqdata: nil)
        let passiveCaptchaChallenge = PassiveCaptchaChallenge(passiveCaptchaData: passiveCaptchaData)
        // wait to make sure that the token will be ready by the time we call fetchToken
        try await Task.sleep(nanoseconds: 6_000_000_000)
        let hcaptchaToken = try await passiveCaptchaChallenge.fetchToken()
        XCTAssertNotNil(hcaptchaToken)
        let isReady = await passiveCaptchaChallenge.isTokenReady
        XCTAssertTrue(isReady, "Token should be ready if not expired")
        let passiveCaptchaEvents = STPAnalyticsClient.sharedClient._testLogHistory.map({ $0["event"] as? String }).filter({ $0?.starts(with: "elements.captcha.passive") ?? false })
        XCTAssertEqual(passiveCaptchaEvents, ["elements.captcha.passive.init", "elements.captcha.passive.execute", "elements.captcha.passive.success"])
        let successAnalytic = STPAnalyticsClient.sharedClient._testLogHistory.first(where: { $0["event"] as? String == "elements.captcha.passive.success" })
        XCTAssertEqual(successAnalytic?["site_key"] as? String, siteKey)
    }

    func testPassiveCaptchaTimeout() async throws {
        let passiveCaptchaData = PassiveCaptchaData(siteKey: siteKey, rqdata: nil)
        let passiveCaptchaChallenge = PassiveCaptchaChallenge(passiveCaptchaData: passiveCaptchaData, hcaptchaFactory: TestDelayHCaptchaFactory())
        let startTime = Date()
        let hcaptchaTokenResult = await withTimeout(1) {
            try await passiveCaptchaChallenge.fetchToken()
        }
        XCTAssertLessThan(Date().timeIntervalSince(startTime), 1.5)
        // should return TimeoutError
        XCTAssertFalse(hcaptchaTokenResult.success)
        XCTAssertThrowsError(try hcaptchaTokenResult.get())
        let passiveCaptchaEvents = STPAnalyticsClient.sharedClient._testLogHistory.map({ $0["event"] as? String }).filter({ $0?.starts(with: "elements.captcha.passive") ?? false })
        XCTAssertEqual(passiveCaptchaEvents, ["elements.captcha.passive.init", "elements.captcha.passive.execute"])
    }

    func testPassiveCaptchaLongTimeout() async throws {
        let passiveCaptchaData = PassiveCaptchaData(siteKey: siteKey, rqdata: nil)
        let passiveCaptchaChallenge = PassiveCaptchaChallenge(passiveCaptchaData: passiveCaptchaData)
        let startTime = Date()
        let hcaptchaToken = try await withTimeout(30) {
            try await passiveCaptchaChallenge.fetchToken()
        }.get()
        // didn't time out because it finished early
        XCTAssertLessThan(Date().timeIntervalSince(startTime), 10)
        XCTAssertNotNil(hcaptchaToken)
    }

    func testTokenResetAndRefetchAfterExpiration() async throws {
        // Use a very short expiration time (5 seconds) for testing
        let passiveCaptchaData = PassiveCaptchaData(siteKey: siteKey, rqdata: nil, tokenTimeoutMs: 5000)
        let passiveCaptchaChallenge = PassiveCaptchaChallenge(passiveCaptchaData: passiveCaptchaData, hcaptchaFactory: PassiveHCaptchaFactory())

        // Fetch first token
        let token = try await passiveCaptchaChallenge.fetchToken()
        XCTAssertNotNil(token)

        // Verify token is ready
        var isReadyBefore = await passiveCaptchaChallenge.isTokenReady
        XCTAssertTrue(isReadyBefore, "Token should be ready after first fetch")

        // Fetch a token before expiration - should succeed without fetching a new token
        let sameToken = try await passiveCaptchaChallenge.fetchToken()
        XCTAssertNotNil(sameToken)

        // Verify token is ready
        isReadyBefore = await passiveCaptchaChallenge.isTokenReady
        XCTAssertTrue(isReadyBefore, "Token should be ready after first fetch")

        let passiveCaptchaEvents = STPAnalyticsClient.sharedClient._testLogHistory.map({ $0["event"] as? String }).filter({ $0?.starts(with: "elements.captcha.passive") ?? false })
        // We should not see these events more than once because we shouldn't need to fetch more than once
        XCTAssertEqual(passiveCaptchaEvents, ["elements.captcha.passive.init", "elements.captcha.passive.execute", "elements.captcha.passive.success"])

        // Wait for session to expire
        try await Task.sleep(nanoseconds: 5_000_000_000)

        // Check that expiration triggers reset
        let isReadyAfter = await passiveCaptchaChallenge.isTokenReady
        XCTAssertFalse(isReadyAfter, "Token should not be ready after session expiration")

        // Fetch a new token after expiration - should succeed with a new token
        let newToken = try await passiveCaptchaChallenge.fetchToken()
        XCTAssertNotNil(newToken)

        // Verify token is ready again after successful refetch
        let isReadyFinal = await passiveCaptchaChallenge.isTokenReady
        XCTAssertTrue(isReadyFinal, "Token should be ready after refetch")

        let passiveCaptchaExecuteEvents = STPAnalyticsClient.sharedClient._testLogHistory.map({ $0["event"] as? String }).filter({ $0?.starts(with: "elements.captcha.passive.execute") ?? false })
        XCTAssertEqual(passiveCaptchaExecuteEvents.count, 2, "Should have re-fetched token after expiration")
    }
}
