//
//  AttestationChallengeTests.swift
//  StripePaymentSheetTests
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

class AttestationChallengeTests: XCTestCase {
    var mockAttestService: MockAppAttestService!
    var mockAttestBackend: MockAttestBackend!
    var stripeAttest: StripeAttest!
    let apiClient = STPAPIClient(publishableKey: "pk_test_abc123")

    override func setUp() {
        super.setUp()
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
        // Reset delays for next test
        let expectation = self.expectation(description: "Wait for teardown")
        Task { @MainActor in
            await mockAttestService.setAttestationDelay(0)
            await mockAttestService.setGenerateAssertionDelay(0)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 5)
        super.tearDown()
    }

    func testAttestationChallenge() async throws {
        let attestationChallenge = AttestationChallenge(stripeAttest: stripeAttest)
        // wait to make sure that the assertion will be ready by the time we call fetchAssertion
        try await Task.sleep(nanoseconds: 6_000_000_000)
        let startTime = Date()
        let assertion = try await withTimeout(30) {
            await attestationChallenge.fetchAssertion()
        }.get()?.flatMap { $0 }
        // didn't take the full timeout time, exited early
        XCTAssertLessThan(Date().timeIntervalSince(startTime), 10)
        XCTAssertNotNil(assertion)
        let attestationEvents = STPAnalyticsClient.sharedClient._testLogHistory.map({ $0["event"] as? String }).filter({ $0?.starts(with: "elements.attestation.confirmation") ?? false })
        XCTAssertEqual(attestationEvents, ["elements.attestation.confirmation.prepare", "elements.attestation.confirmation.prepare_succeeded", "elements.attestation.confirmation.request_token", "elements.attestation.confirmation.request_token_succeeded"])
        await attestationChallenge.complete()
    }

    func testAttestationChallengeTimeoutDuringAttestation() async throws {
        // Inject a delay longer than the timeout to force cancellation during attestation
        await mockAttestService.setAttestationDelay(5.0)
        let attestationChallenge = AttestationChallenge(stripeAttest: stripeAttest)
        let startTime = Date()
        let assertionResult = await withTimeout(1) {
            await attestationChallenge.fetchAssertion()
        }
        await attestationChallenge.complete()
        XCTAssertLessThan(Date().timeIntervalSince(startTime), 2)
        // should return TimeoutError
        XCTAssertFalse(assertionResult.success)
        XCTAssertThrowsError(try assertionResult.get())
    }

    func testAttestationChallengeTimeoutDuringAssertion() async throws {
        // Inject a delay longer than the timeout to force cancellation during assertion
        await mockAttestService.setAssertionDelay(5.0)
        let attestationChallenge = AttestationChallenge(stripeAttest: stripeAttest)
        let startTime = Date()
        let assertionResult = await withTimeout(1) {
            await attestationChallenge.fetchAssertion()
        }
        await attestationChallenge.complete()
        XCTAssertLessThan(Date().timeIntervalSince(startTime), 2)
        // should return TimeoutError
        XCTAssertFalse(assertionResult.success)
        XCTAssertThrowsError(try assertionResult.get())
    }
}
