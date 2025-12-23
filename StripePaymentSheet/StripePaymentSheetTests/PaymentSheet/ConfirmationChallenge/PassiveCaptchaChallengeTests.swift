//
//  PassiveCaptchaChallengeTests.swift
//  StripePaymentSheetTests
//
//  Created by Joyce Qin on 8/21/25.
//

@_spi(STP) @testable import StripePaymentSheet
@_spi(STP) @testable import StripePayments
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

    struct TestHCaptchaFactory: HCaptchaFactory {
        let shouldInjectDelay: Bool
        let sessionExpiration: TimeInterval

        init(shouldInjectDelay: Bool = false, sessionExpiration: TimeInterval = 29 * 60) {
            self.shouldInjectDelay = shouldInjectDelay
            self.sessionExpiration = sessionExpiration
        }

        func create(siteKey: String, rqdata: String?) throws -> HCaptcha {
            let hcaptcha = try HCaptcha(apiKey: siteKey,
                                        passiveApiKey: true,
                                        rqdata: rqdata,
                                        host: "stripecdn.com")
            if shouldInjectDelay {
                hcaptcha.manager.shouldDelayToken = true
            }
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
        let passiveCaptchaChallenge = PassiveCaptchaChallenge(passiveCaptchaData: passiveCaptchaData, hcaptchaFactory: TestHCaptchaFactory(shouldInjectDelay: true))
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
        let passiveCaptchaData = PassiveCaptchaData(siteKey: siteKey, rqdata: nil)
        // Use a very short expiration time (5 seconds) for testing
        let testFactory = TestHCaptchaFactory(sessionExpiration: 5.0)
        let passiveCaptchaChallenge = PassiveCaptchaChallenge(passiveCaptchaData: passiveCaptchaData, hcaptchaFactory: testFactory)

        // Fetch first token
        let firstToken = try await passiveCaptchaChallenge.fetchToken()
        XCTAssertNotNil(firstToken)

        // Verify token is ready
        let isReadyBefore = await passiveCaptchaChallenge.isTokenReady
        XCTAssertTrue(isReadyBefore, "Token should be ready after first fetch")

        // Wait for session to expire (5 seconds + small buffer)
        try await Task.sleep(nanoseconds: 5_500_000_000)

        // Check that isTokenReady triggers reset
        let isReadyAfter = await passiveCaptchaChallenge.isTokenReady
        XCTAssertFalse(isReadyAfter, "Token should not be ready after session expiration")

        // Fetch a new token after expiration - should succeed with a new token
        let secondToken = try await passiveCaptchaChallenge.fetchToken()
        XCTAssertNotNil(secondToken)

        // Verify token is ready again after successful refetch
        let isReadyFinal = await passiveCaptchaChallenge.isTokenReady
        XCTAssertTrue(isReadyFinal, "Token should be ready after refetch")
    }
}
