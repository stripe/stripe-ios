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

    // MARK: - Confirmation challenge tests
    func testConfirmationChallenge() async throws {
        let confirmationChallenge = ConfirmationChallenge(elementsSession: elementsSession, stripeAttest: stripeAttest)
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

        XCTAssertTrue(STPAnalyticsClient.sharedClient._testLogHistory.map({ $0["event"] as? String }).contains("elements.attestation.confirmation.request_token.succeeded"))
        await confirmationChallenge.complete()
    }

    func testConfirmationChallengeCaptchaTimeout() async {
        let confirmationChallenge = ConfirmationChallenge(elementsSession: elementsSession, stripeAttest: stripeAttest, hcaptchaFactory: TestDelayHCaptchaFactory())
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

    func testConfirmationChallengeAttestationTimeoutDuringAttestation() async throws {
        // Inject a delay longer than timeout to force attestation to time out
        await mockAttestService.setAttestationDelay(15.0)
        let confirmationChallenge = ConfirmationChallenge(elementsSession: elementsSession, stripeAttest: stripeAttest)
        await confirmationChallenge.setTimeout(timeout: 5)
        let startTime = Date()
        let (hcaptcha, assertion) = await confirmationChallenge.fetchTokensWithTimeout()
        XCTAssertLessThan(Date().timeIntervalSince(startTime), 15)
        // hcaptcha takes ~3-4s in test environment, so it should be fine
        XCTAssertNotNil(hcaptcha)
        // should return nil due to timeout
        XCTAssertNil(assertion)
        let timeoutAnalytic = STPAnalyticsClient.sharedClient._testLogHistory.last(where: { $0["event"] as? String == "elements.attestation.confirmation.error" })
        XCTAssertEqual(timeoutAnalytic?["error_type"] as? String, "StripeCore.TimeoutError")
        await confirmationChallenge.complete()
    }

    func testConfirmationChallengeAttestationTimeoutDuringAssertion() async throws {
        // Inject a delay longer than timeout to force attestation to time out
        await mockAttestService.setAssertionDelay(15.0)
        let confirmationChallenge = ConfirmationChallenge(elementsSession: elementsSession, stripeAttest: stripeAttest)
        await confirmationChallenge.setTimeout(timeout: 5)
        let startTime = Date()
        let (hcaptcha, assertion) = await confirmationChallenge.fetchTokensWithTimeout()
        XCTAssertLessThan(Date().timeIntervalSince(startTime), 15)
        // hcaptcha takes ~3-4s in test environment, so it should be fine
        XCTAssertNotNil(hcaptcha)
        // should return nil due to timeout
        XCTAssertNil(assertion)
        let timeoutAnalytic = STPAnalyticsClient.sharedClient._testLogHistory.last(where: { $0["event"] as? String == "elements.attestation.confirmation.error" })
        XCTAssertEqual(timeoutAnalytic?["error_type"] as? String, "StripeCore.TimeoutError")
        await confirmationChallenge.complete()
    }

    func testConfirmationChallengeTimeout() async throws {
        // Inject delays to force both to time out
        await mockAttestService.setAssertionDelay(15.0)
        let confirmationChallenge = ConfirmationChallenge(elementsSession: elementsSession, stripeAttest: stripeAttest, hcaptchaFactory: TestDelayHCaptchaFactory())
        await confirmationChallenge.setTimeout(timeout: 1)
        let startTime = Date()
        let (hcaptcha, assertion) = await confirmationChallenge.fetchTokensWithTimeout()
        XCTAssertLessThan(Date().timeIntervalSince(startTime), 2)
        // should return nil due to timeout
        XCTAssertNil(hcaptcha)
        // should return nil due to timeout
        XCTAssertNil(assertion)
    }

    // MARK: - Scoped requests

    private func makeAttestationOnlyChallenge() -> ConfirmationChallenge {
        let session = STPElementsSession.decodedObject(fromAPIResponse: [
            "session_id": "test_session",
            "payment_method_preference": ["ordered_payment_method_types": ["card"]],
            "flags": ["elements_mobile_attest_on_intent_confirmation": true],
        ])!
        return ConfirmationChallenge(elementsSession: session, stripeAttest: stripeAttest)
    }

    func testScopedRequestsUseFreshAssertions() async throws {
        // Given a challenge reused across confirmation attempts
        let challenge = makeAttestationOnlyChallenge()

        // When two signed requests finish successfully
        let first = try await challenge.withRadarOptions(for: .card) { options in
            try XCTUnwrap(options?.iosVerificationObject)
        }
        let second = try await challenge.withRadarOptions(for: .card) { options in
            try XCTUnwrap(options?.iosVerificationObject)
        }

        // Then the second request gets a new assertion
        XCTAssertNotEqual(first, second)
    }

    func testScopedRequestFailureReleasesAssertion() async throws {
        // Given a signed request that fails
        let challenge = makeAttestationOnlyChallenge()
        let requestError = NSError(domain: "test", code: 1)
        do {
            try await challenge.withRadarOptions(for: .card) { options in
                XCTAssertNotNil(options?.iosVerificationObject)
                throw requestError
            }
            XCTFail("Expected the request error")
        } catch {
            XCTAssertEqual(error as NSError, requestError)
        }

        // When the request is retried
        let assertion = try await withTimeout(5) {
            try await challenge.withRadarOptions(for: .card) { options in
                try XCTUnwrap(options?.iosVerificationObject)
            }
        }.get()

        // Then cleanup has unblocked the next assertion
        XCTAssertNotNil(assertion["ios_assertion_object"])
    }

    func testScopedRequestCancellationReleasesAssertion() async throws {
        // Given an in-flight signed request
        let challenge = makeAttestationOnlyChallenge()
        let started = expectation(description: "Signed request started")
        let request = Task {
            try await challenge.withRadarOptions(for: .card) { options in
                XCTAssertNotNil(options?.iosVerificationObject)
                started.fulfill()
                try await Task.sleep(nanoseconds: 30_000_000_000)
            }
        }
        await fulfillment(of: [started], timeout: 5)

        // When the request is canceled
        request.cancel()
        do {
            try await request.value
            XCTFail("Expected cancellation")
        } catch {
            XCTAssertTrue(error is CancellationError)
        }

        // Then the next request can acquire an assertion
        _ = try await withTimeout(5) {
            try await challenge.withRadarOptions(for: .card) { options in
                try XCTUnwrap(options?.iosVerificationObject)
            }
        }.get()
    }

    func testConcurrentScopedRequestsUseDistinctAssertions() async throws {
        // Given multiple requests sharing a challenge
        let challenge = makeAttestationOnlyChallenge()

        // When their signed requests overlap
        let assertions = try await withThrowingTaskGroup(of: String.self) { group in
            for _ in 0..<3 {
                group.addTask {
                    try await challenge.withRadarOptions(for: .card) { options in
                        await Task.yield()
                        return try XCTUnwrap(options?.iosVerificationObject?["ios_assertion_object"])
                    }
                }
            }
            var assertions: [String] = []
            for try await assertion in group { assertions.append(assertion) }
            return assertions
        }

        // Then every request has its own assertion
        XCTAssertEqual(Set(assertions).count, 3)
    }

    // MARK: - makeRadarOptions Payment Method Type Tests
    func testMakeRadarOptionsForCard() async throws {
        let confirmationChallenge = ConfirmationChallenge(elementsSession: elementsSession, stripeAttest: stripeAttest)
        await confirmationChallenge.setTimeout(timeout: 30)
        let radarOptions = await confirmationChallenge.makeRadarOptions(for: .card)
        // Card payment methods should return radar options
        XCTAssertNotNil(radarOptions)
        XCTAssertNotNil(radarOptions?.hcaptchaToken)
        XCTAssertNotNil(radarOptions?.iosVerificationObject)
        await confirmationChallenge.complete()
    }

    func testMakeRadarOptionsConsumesPassiveCaptchaTask() async {
        // Given a challenge whose captcha creation fails deterministically
        let counter = PassiveCaptchaCreateCounter()
        let factory = CountingFailingPassiveCaptchaFactory(counter: counter)
        let confirmationChallenge = ConfirmationChallenge(elementsSession: elementsSession, stripeAttest: stripeAttest, hcaptchaFactory: factory)

        // When radar options are requested twice
        _ = await confirmationChallenge.makeRadarOptions(for: .card)
        _ = await confirmationChallenge.makeRadarOptions(for: .card)

        // Then each request should execute its own captcha challenge
        XCTAssertEqual(counter.count, 2)
        await confirmationChallenge.complete()
    }

    func testMakeRadarOptionsForLink() async throws {
        let confirmationChallenge = ConfirmationChallenge(elementsSession: elementsSession, stripeAttest: stripeAttest)
        await confirmationChallenge.setTimeout(timeout: 30)
        let radarOptions = await confirmationChallenge.makeRadarOptions(for: .link)
        // Link payment methods should return radar options
        XCTAssertNotNil(radarOptions)
        XCTAssertNotNil(radarOptions?.hcaptchaToken)
        XCTAssertNotNil(radarOptions?.iosVerificationObject)
        await confirmationChallenge.complete()
    }

    func testMakeRadarOptionsForUSBankAccount() async throws {
        let confirmationChallenge = ConfirmationChallenge(elementsSession: elementsSession, stripeAttest: stripeAttest)
        await confirmationChallenge.setTimeout(timeout: 30)
        let radarOptions = await confirmationChallenge.makeRadarOptions(for: .USBankAccount)
        // US Bank Account payment methods should not return radar options
        XCTAssertNil(radarOptions)
        await confirmationChallenge.complete()
    }

}
