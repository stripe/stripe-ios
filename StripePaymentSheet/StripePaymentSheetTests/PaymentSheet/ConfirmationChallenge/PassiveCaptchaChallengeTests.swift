//
//  PassiveCaptchaChallengeTests.swift
//  StripePaymentSheetTests
//
//  Created by Joyce Qin on 8/21/25.
//

@_spi(STP) @testable import StripePayments
@_spi(STP) @testable import StripePaymentSheet
import XCTest

enum PassiveCaptchaTestError: Error {
    case expected
}

final class PassiveCaptchaCreateCounter {
    private let lock = NSLock()
    private var value = 0

    var count: Int {
        lock.lock()
        defer { lock.unlock() }
        return value
    }

    func increment() {
        lock.lock()
        defer { lock.unlock() }
        value += 1
    }
}

struct CountingFailingPassiveCaptchaFactory: HCaptchaFactory {
    let counter: PassiveCaptchaCreateCounter

    func create(siteKey: String, rqdata: String?) throws -> HCaptcha {
        counter.increment()
        throw PassiveCaptchaTestError.expected
    }
}

class PassiveCaptchaChallengeTests: XCTestCase {
    var window: UIWindow?

    override func setUp() {
        super.setUp()
        // Clear analytics at the start of each test to prevent contamination from lingering
        // background tasks started by a previous test.
        STPAnalyticsClient.sharedClient._testLogHistory = []
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

    private func waitUntilTokenIsReady(_ passiveCaptchaChallenge: PassiveCaptchaChallenge) async throws {
        try await withTimeout(30) {
            while !(await passiveCaptchaChallenge.isTokenReady) {
                try await Task.sleep(nanoseconds: 100_000_000)
            }
        }.get()
    }

    func testPassiveCaptcha() async throws {
        let passiveCaptchaData = PassiveCaptchaData(siteKey: siteKey, rqdata: nil)
        let passiveCaptchaChallenge = PassiveCaptchaChallenge(passiveCaptchaData: passiveCaptchaData)

        // Wait to make sure that the token will be ready by the time we consume it
        try await waitUntilTokenIsReady(passiveCaptchaChallenge)
        let isReadyBeforeConsumption = await passiveCaptchaChallenge.isTokenReady
        XCTAssertTrue(isReadyBeforeConsumption, "Token should be ready if not expired")

        let hcaptchaToken = try await passiveCaptchaChallenge.consumeToken()
        XCTAssertFalse(hcaptchaToken.value.isEmpty)
        XCTAssertTrue(hcaptchaToken.wasReady)
        let isReadyAfterConsumption = await passiveCaptchaChallenge.isTokenReady
        XCTAssertFalse(isReadyAfterConsumption, "Token should be discarded after consumption")

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
            try await passiveCaptchaChallenge.consumeToken()
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
            try await passiveCaptchaChallenge.consumeToken()
        }.get()
        // didn't time out because it finished early
        XCTAssertLessThan(Date().timeIntervalSince(startTime), 10)
        XCTAssertFalse(hcaptchaToken.value.isEmpty)
    }

    func testTokenResetAndRefetchAfterExpiration() async throws {
        // Use a very short expiration time for testing
        let passiveCaptchaData = PassiveCaptchaData(siteKey: siteKey, rqdata: nil, tokenTimeoutSeconds: 2)
        let passiveCaptchaChallenge = PassiveCaptchaChallenge(passiveCaptchaData: passiveCaptchaData, hcaptchaFactory: PassiveHCaptchaFactory())

        // Wait for the preloaded token to be ready
        try await waitUntilTokenIsReady(passiveCaptchaChallenge)
        let isReadyBefore = await passiveCaptchaChallenge.isTokenReady
        XCTAssertTrue(isReadyBefore, "Token should be ready before expiration")

        // Wait for session to expire
        try await Task.sleep(nanoseconds: 2_100_000_000)

        // Check that expiration triggers reset
        let isReadyAfter = await passiveCaptchaChallenge.isTokenReady
        XCTAssertFalse(isReadyAfter, "Token should not be ready after session expiration")

        // Consume after expiration - should fetch a new token
        let newToken = try await passiveCaptchaChallenge.consumeToken()
        XCTAssertFalse(newToken.value.isEmpty)
        XCTAssertFalse(newToken.wasReady)

        // Consuming the new token should leave no token cached
        let isReadyFinal = await passiveCaptchaChallenge.isTokenReady
        XCTAssertFalse(isReadyFinal, "Token should be discarded after consumption")

        let passiveCaptchaExecuteEvents = STPAnalyticsClient.sharedClient._testLogHistory.map({ $0["event"] as? String }).filter({ $0?.starts(with: "elements.captcha.passive.execute") ?? false })
        XCTAssertEqual(passiveCaptchaExecuteEvents.count, 2, "Should have re-fetched token after expiration")
    }

    func testConcurrentConsumeTokenRequestsDoNotShareTask() async {
        // Given a preloaded token task that fails deterministically
        let counter = PassiveCaptchaCreateCounter()
        let factory = CountingFailingPassiveCaptchaFactory(counter: counter)
        let passiveCaptchaData = PassiveCaptchaData(siteKey: siteKey, rqdata: nil)
        let passiveCaptchaChallenge = PassiveCaptchaChallenge(passiveCaptchaData: passiveCaptchaData, hcaptchaFactory: factory)

        // When two callers consume concurrently
        let firstTokenTask = Task { try? await passiveCaptchaChallenge.consumeToken() }
        let secondTokenTask = Task { try? await passiveCaptchaChallenge.consumeToken() }
        _ = await (firstTokenTask.value, secondTokenTask.value)

        // Then each caller should execute its own challenge
        XCTAssertEqual(counter.count, 2)
    }
}
