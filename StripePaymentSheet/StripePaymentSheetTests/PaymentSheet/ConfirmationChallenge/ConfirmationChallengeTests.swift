//
//  ConfirmationChallengeTests.swift
//  StripePaymentSheet
//
//  Created by Joyce Qin on 10/29/25.
//

import Foundation

@_spi(STP) @testable import StripeCore
@_spi(STP) @testable import StripeCoreTestUtils
@_spi(STP) @testable import StripePayments
@_spi(STP) @testable import StripePaymentSheet
@_spi(STP) @testable import StripePaymentsObjcTestUtils
import XCTest

class ConfirmationChallengeTests: XCTestCase {
    var window: UIWindow?
    var mockAttestService: MockAppAttestService!
    var mockAttestBackend: MockAttestBackend!
    var stripeAttest: StripeAttest!
    let apiClient = STPAPIClient(publishableKey: "pk_test_abc123")

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
        self.mockAttestBackend = MockAttestBackend()
        self.mockAttestService = MockAppAttestService()
        self.stripeAttest = StripeAttest(appAttestService: mockAttestService, appAttestBackend: mockAttestBackend, apiClient: apiClient)

        let expectation = self.expectation(description: "Wait for setup")
        // Reset storage
        Task { @MainActor in
            await UserDefaults.standard.removeObject(forKey: self.stripeAttest.defaultsKeyForSetting(.dailyAttemptCount))
            await UserDefaults.standard.removeObject(forKey: self.stripeAttest.defaultsKeyForSetting(.firstAttemptToday))
            await stripeAttest.resetKey()
            await mockAttestService.setAttestationUsingDevelopmentEnvironment(true)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 5)
    }

    override func tearDown() {
        // Sleep to allow any background tasks to complete before clearing analytics
        Thread.sleep(forTimeInterval: 1.0)
        STPAnalyticsClient.sharedClient._testLogHistory = []
        window?.isHidden = true
        window = nil
        // Reset delays for next test
        let expectation = self.expectation(description: "Wait for teardown")
        Task { @MainActor in
            await mockAttestService.setAttestationDelay(0)
            await mockAttestService.setAssertionDelay(0)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 5)
        super.tearDown()
    }

    // OCS mobile test key from https://dashboard.hcaptcha.com/sites/edit/143aadb6-fb60-4ab6-b128-f7fe53426d4a
    let siteKey: String = "143aadb6-fb60-4ab6-b128-f7fe53426d4a"

    /// A test-only HCaptcha factory that delays token responses to ensure timeout behavior
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

    var elementsSession: STPElementsSession {
        let apiResponse: [String: Any] = ["payment_method_preference": ["ordered_payment_method_types": ["123"],
                                                                        "country_code": "US", ] as [String: Any],
                                          "session_id": "123",
                                          "config_id": "123",
                                          "apple_pay_preference": "enabled",
                                          "flags": [
                                            "elements_enable_passive_captcha": true,
                                            "elements_mobile_attest_on_intent_confirmation": true,
                                          ],
                                          "passive_captcha": ["site_key": siteKey],

        ]
        return STPElementsSession.decodedObject(fromAPIResponse: apiResponse)!
    }

    // MARK: - Passive Captcha Tests
    func testPassiveCaptchaConfirmationChallenge() async throws {
        let confirmationChallenge = ConfirmationChallenge(enablePassiveCaptcha: true, enableAttestation: false, elementsSession: elementsSession, stripeAttest: stripeAttest)
        await confirmationChallenge.setTimeout(timeout: 30)
        // wait to make sure that the token will be ready by the time we call fetchToken
        try await Task.sleep(nanoseconds: 6_000_000_000)
        let startTime = Date()
        let (hcaptchaToken, _) = await confirmationChallenge.fetchTokensWithTimeout()
        // didn't take the full timeout time, exited early
        XCTAssertLessThan(Date().timeIntervalSince(startTime), 10)
        XCTAssertNotNil(hcaptchaToken)
        let passiveCaptchaEvents = STPAnalyticsClient.sharedClient._testLogHistory.map({ $0["event"] as? String }).filter({ $0?.starts(with: "elements.captcha.passive") ?? false })
        XCTAssertEqual(passiveCaptchaEvents, ["elements.captcha.passive.init", "elements.captcha.passive.execute", "elements.captcha.passive.success", "elements.captcha.passive.attach"])
        let successAnalytic = STPAnalyticsClient.sharedClient._testLogHistory.first(where: { $0["event"] as? String == "elements.captcha.passive.success" })
        XCTAssertEqual(successAnalytic?["site_key"] as? String, siteKey)
        let attachAnalytic = STPAnalyticsClient.sharedClient._testLogHistory.first(where: { $0["event"] as? String == "elements.captcha.passive.attach" })
        // should be ready
        XCTAssertEqual(attachAnalytic?["is_ready"] as? Bool, true)
    }

    func testPassiveCaptchaConfirmationChallengeTimeout() async {
        let confirmationChallenge = ConfirmationChallenge(enablePassiveCaptcha: true, enableAttestation: false, elementsSession: elementsSession, stripeAttest: stripeAttest, hcaptchaFactory: TestDelayHCaptchaFactory())
        await confirmationChallenge.setTimeout(timeout: 1)
        let startTime = Date()
        let (hcaptchaToken, _) = await confirmationChallenge.fetchTokensWithTimeout()
        XCTAssertLessThan(Date().timeIntervalSince(startTime), 2)
        // should return nil due to timeout
        XCTAssertNil(hcaptchaToken)
        let timeoutAnalytic = STPAnalyticsClient.sharedClient._testLogHistory.last(where: { $0["event"] as? String == "elements.captcha.passive.error" })
        XCTAssertEqual(timeoutAnalytic?["error_type"] as? String, "StripeCore.TimeoutError")
    }

    // MARK: - Attestation Tests
    func testAttestationConfirmationChallenge() async throws {
        let confirmationChallenge = ConfirmationChallenge(enablePassiveCaptcha: false, enableAttestation: true, elementsSession: elementsSession, stripeAttest: stripeAttest)
        await confirmationChallenge.setTimeout(timeout: 30)
        // wait to make sure that the token will be ready by the time we call fetchToken
        try await Task.sleep(nanoseconds: 6_000_000_000)
        let startTime = Date()
        let (_, assertion) = await confirmationChallenge.fetchTokensWithTimeout()
        // didn't take the full timeout time, exited early
        XCTAssertLessThan(Date().timeIntervalSince(startTime), 10)
        XCTAssertNotNil(assertion)
        XCTAssertTrue(STPAnalyticsClient.sharedClient._testLogHistory.map({ $0["event"] as? String }).contains("elements.attestation.confirmation.request_token_succeeded"))
        await confirmationChallenge.complete()
    }

    func testAttestationConfirmationChallengeTimeoutDuringAttestation() async throws {
        // Inject a delay longer than the timeout to force cancellation
        await mockAttestService.setAttestationDelay(5.0)
        let confirmationChallenge = ConfirmationChallenge(enablePassiveCaptcha: false, enableAttestation: true, elementsSession: elementsSession, stripeAttest: stripeAttest)
        await confirmationChallenge.setTimeout(timeout: 1)
        let startTime = Date()
        let (_, assertion) = await confirmationChallenge.fetchTokensWithTimeout()
        XCTAssertLessThan(Date().timeIntervalSince(startTime), 2)
        // should return nil due to timeout
        XCTAssertNil(assertion)
        let timeoutAnalytic = STPAnalyticsClient.sharedClient._testLogHistory.last(where: { $0["event"] as? String == "elements.attestation.confirmation.error" })
        XCTAssertEqual(timeoutAnalytic?["error_type"] as? String, "StripeCore.TimeoutError")
        await confirmationChallenge.complete()
    }

    func testAttestationConfirmationChallengeTimeoutDuringAssertion() async throws {
        // Inject a delay longer than the timeout to force cancellation
        await mockAttestService.setAssertionDelay(5.0)
        let confirmationChallenge = ConfirmationChallenge(enablePassiveCaptcha: false, enableAttestation: true, elementsSession: elementsSession, stripeAttest: stripeAttest)
        await confirmationChallenge.setTimeout(timeout: 1)
        let startTime = Date()
        let (_, assertion) = await confirmationChallenge.fetchTokensWithTimeout()
        XCTAssertLessThan(Date().timeIntervalSince(startTime), 2)
        // should return nil due to timeout
        XCTAssertNil(assertion)
        let timeoutAnalytic = STPAnalyticsClient.sharedClient._testLogHistory.last(where: { $0["event"] as? String == "elements.attestation.confirmation.error" })
        XCTAssertEqual(timeoutAnalytic?["error_type"] as? String, "StripeCore.TimeoutError")
        await confirmationChallenge.complete()
    }

    // MARK: - Confirmation challenge tests
    func testConfirmationChallenge() async throws {
        let confirmationChallenge = ConfirmationChallenge(enablePassiveCaptcha: true, enableAttestation: true, elementsSession: elementsSession, stripeAttest: stripeAttest)
        await confirmationChallenge.setTimeout(timeout: 30)
        // wait to make sure that the tokens will be ready by the time we call fetchToken
        try await Task.sleep(nanoseconds: 6_000_000_000)
        let startTime = Date()
        let (hcaptcha, assertion) = await confirmationChallenge.fetchTokensWithTimeout()
        // didn't take the full timeout time, exited early
        XCTAssertLessThan(Date().timeIntervalSince(startTime), 10)
        XCTAssertNotNil(hcaptcha)
        XCTAssertNotNil(assertion)

        let passiveCaptchaEvents = STPAnalyticsClient.sharedClient._testLogHistory.map({ $0["event"] as? String }).filter({ $0?.starts(with: "elements.captcha.passive") ?? false })
        XCTAssertEqual(passiveCaptchaEvents, ["elements.captcha.passive.init", "elements.captcha.passive.execute", "elements.captcha.passive.success", "elements.captcha.passive.attach"])
        let successAnalytic = STPAnalyticsClient.sharedClient._testLogHistory.first(where: { $0["event"] as? String == "elements.captcha.passive.success" })
        XCTAssertEqual(successAnalytic?["site_key"] as? String, siteKey)
        let attachAnalytic = STPAnalyticsClient.sharedClient._testLogHistory.first(where: { $0["event"] as? String == "elements.captcha.passive.attach" })
        // should be ready
        XCTAssertEqual(attachAnalytic?["is_ready"] as? Bool, true)

        XCTAssertTrue(STPAnalyticsClient.sharedClient._testLogHistory.map({ $0["event"] as? String }).contains("elements.attestation.confirmation.request_token_succeeded"))
        await confirmationChallenge.complete()
    }

    func testConfirmationChallengeCaptchaTimeout() async {
        let confirmationChallenge = ConfirmationChallenge(enablePassiveCaptcha: true, enableAttestation: true, elementsSession: elementsSession, stripeAttest: stripeAttest, hcaptchaFactory: TestDelayHCaptchaFactory())
        await confirmationChallenge.setTimeout(timeout: 1)
        let startTime = Date()
        let (hcaptcha, assertion) = await confirmationChallenge.fetchTokensWithTimeout()
        XCTAssertLessThan(Date().timeIntervalSince(startTime), 2)
        // should return nil due to timeout
        XCTAssertNil(hcaptcha)
        // assertion is really fast in test mode, so it returns in time
        XCTAssertNotNil(assertion)
        await confirmationChallenge.complete()
    }

    func testConfirmationChallengeAttestationTimeout() async throws {
        // Inject a delay longer than timeout to force assertion to time out
        await mockAttestService.setAssertionDelay(15.0)
        let confirmationChallenge = ConfirmationChallenge(enablePassiveCaptcha: true, enableAttestation: true, elementsSession: elementsSession, stripeAttest: stripeAttest)
        await confirmationChallenge.setTimeout(timeout: 5)
        let startTime = Date()
        let (hcaptcha, assertion) = await confirmationChallenge.fetchTokensWithTimeout()
        XCTAssertLessThan(Date().timeIntervalSince(startTime), 15)
        // hcaptcha takes ~3-4s in test environment, so it should be fine
        XCTAssertNotNil(hcaptcha)
        // should return nil due to timeout
        XCTAssertNil(assertion)
    }

    func testConfirmationChallengeTimeout() async throws {
        // Inject delays to force both to time out
        await mockAttestService.setAssertionDelay(15.0)
        let confirmationChallenge = ConfirmationChallenge(enablePassiveCaptcha: true, enableAttestation: true, elementsSession: elementsSession, stripeAttest: stripeAttest, hcaptchaFactory: TestDelayHCaptchaFactory())
        await confirmationChallenge.setTimeout(timeout: 1)
        let startTime = Date()
        let (hcaptcha, assertion) = await confirmationChallenge.fetchTokensWithTimeout()
        XCTAssertLessThan(Date().timeIntervalSince(startTime), 2)
        // should return nil due to timeout
        XCTAssertNil(hcaptcha)
        // should return nil due to timeout
        XCTAssertNil(assertion)
    }

    // MARK: - makeRadarOptions Payment Method Type Tests
    func testMakeRadarOptionsForCard() async throws {
        let confirmationChallenge = ConfirmationChallenge(enablePassiveCaptcha: true, enableAttestation: true, elementsSession: elementsSession, stripeAttest: stripeAttest)
        await confirmationChallenge.setTimeout(timeout: 30)
        let radarOptions = await confirmationChallenge.makeRadarOptions(for: .card)
        // Card payment methods should return radar options
        XCTAssertNotNil(radarOptions)
        XCTAssertNotNil(radarOptions?.hcaptchaToken)
        XCTAssertNotNil(radarOptions?.iosVerificationObject)
        await confirmationChallenge.complete()
    }

    func testMakeRadarOptionsForLink() async throws {
        let confirmationChallenge = ConfirmationChallenge(enablePassiveCaptcha: true, enableAttestation: true, elementsSession: elementsSession, stripeAttest: stripeAttest)
        await confirmationChallenge.setTimeout(timeout: 30)
        let radarOptions = await confirmationChallenge.makeRadarOptions(for: .link)
        // Link payment methods should return radar options
        XCTAssertNotNil(radarOptions)
        XCTAssertNotNil(radarOptions?.hcaptchaToken)
        XCTAssertNotNil(radarOptions?.iosVerificationObject)
        await confirmationChallenge.complete()
    }

    func testMakeRadarOptionsForUSBankAccount() async throws {
        let confirmationChallenge = ConfirmationChallenge(enablePassiveCaptcha: true, enableAttestation: true, elementsSession: elementsSession, stripeAttest: stripeAttest)
        await confirmationChallenge.setTimeout(timeout: 30)
        let radarOptions = await confirmationChallenge.makeRadarOptions(for: .USBankAccount)
        // US Bank Account payment methods should not return radar options
        XCTAssertNil(radarOptions)
        await confirmationChallenge.complete()
    }

}
