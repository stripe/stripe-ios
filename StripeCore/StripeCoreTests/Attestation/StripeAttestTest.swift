//
//  StripeAttestTest.swift
//  StripeCore
//

import DeviceCheck
@testable @_spi(STP) import StripeCore
@testable @_spi(STP) import StripeCoreTestUtils
import XCTest

class StripeAttestTest: XCTestCase {
    var mockAttestService: MockAppAttestService!
    var mockAttestBackend: MockAttestBackend!
    var stripeAttest: StripeAttest!
    let apiClient = STPAPIClient(publishableKey: "pk_live_abc123")

    override func setUp() {
        self.mockAttestBackend = MockAttestBackend()
        self.mockAttestService = MockAppAttestService()
        self.stripeAttest = StripeAttest(appAttestService: mockAttestService, appAttestBackend: mockAttestBackend, apiClient: apiClient)

        let expectation = self.expectation(description: "Wait for setup")
        // Reset storage
        Task { @MainActor in
            await UserDefaults.standard.removeObject(forKey: self.stripeAttest.defaultsKeyForSetting(.dailyAttemptCount))
            await UserDefaults.standard.removeObject(forKey: self.stripeAttest.defaultsKeyForSetting(.firstAttemptToday))
            await stripeAttest.resetKey()
            expectation.fulfill()
        }
        waitForExpectations(timeout: 5)
    }

    func testAppAttestService() async {
        try! await stripeAttest.attest()
        let assertionHandle = try! await stripeAttest.assert()
        try! await self.mockAttestBackend.assertionTest(assertion: assertionHandle.assertion)
    }

    func testCanAssertWithoutAttestation() async {
        let assertionHandle = try! await stripeAttest.assert()
        try! await self.mockAttestBackend.assertionTest(assertion: assertionHandle.assertion)
    }

    func testCanOnlyAttestThreeTimesPerDayInProd() async {
        let invalidKeyError = NSError(domain: DCErrorDomain, code: DCError.invalidKey.rawValue, userInfo: nil)

        // First 3 attempts should succeed
        for i in 1...3 {
            // Create and attest a key
            try! await stripeAttest.attest()
            // But fail the assertion, causing the key to be reset
            await mockAttestService.setShouldFailAssertionWithError(invalidKeyError)
            do {
                _ = try await stripeAttest.assert()
                XCTFail("Should not succeed on attempt \(i)")
            } catch {
                if i < 3 {
                    // First 2 attempts should fail with shouldNotAttest (since we're re-attesting)
                    XCTAssertEqual(error as! StripeAttest.AttestationError, StripeAttest.AttestationError.shouldNotAttest)
                } else {
                    // Third attempt should fail with attestationRateLimitExceeded
                    XCTAssertEqual(error as! StripeAttest.AttestationError, StripeAttest.AttestationError.attestationRateLimitExceeded)
                }
            }
        }

        // Fourth attempt should hit rate limit
        do {
            try await stripeAttest.attest()
            XCTFail("Should not succeed on 4th attempt")
        } catch {
            XCTAssertEqual(error as! StripeAttest.AttestationError, StripeAttest.AttestationError.attestationRateLimitExceeded)
        }
    }

    func testCanAttestAsMuchAsNeededInDev() async {
        // Create and attest a key in the dev environment
        await mockAttestService.setAttestationUsingDevelopmentEnvironment(true)
        try! await stripeAttest.attest()
        let invalidKeyError = NSError(domain: DCErrorDomain, code: DCError.invalidKey.rawValue, userInfo: nil)
        // But fail the assertion, which will cause us to try to re-attest the key
        await mockAttestService.setShouldFailAssertionWithError(invalidKeyError)
        do {
            _ = try await stripeAttest.assert()
            XCTFail("Should not succeed")
        } catch {
            // Should get a shouldNotAttest error from the server, as we're re-attesting an already-attested key
            XCTAssertEqual(error as! StripeAttest.AttestationError, StripeAttest.AttestationError.shouldNotAttest)
        }
        // Now that we've failed assertion and re-attestation, the key will be reset.
        // Attesting again should now work, because we're in the dev environment
        // and not constrained by the 24 hour timeout:
        _ = try! await stripeAttest.attest()
    }

    func testAssertionDoesNotAttestIfAlreadyAttested() async {
        do {
            // Create and attest a key
            try! await stripeAttest.attest()
            // But it's an old key, so we'll be allowed to attest a new one (reset daily counters)
            await UserDefaults.standard.set(Date.distantPast, forKey: self.stripeAttest.defaultsKeyForSetting(.firstAttemptToday))
            await UserDefaults.standard.set(0, forKey: self.stripeAttest.defaultsKeyForSetting(.dailyAttemptCount))
            // Always fail the assertions and don't remember attestations:
            let invalidKeyError = NSError(domain: DCErrorDomain, code: DCError.invalidKey.rawValue, userInfo: nil)
            await mockAttestService.setShouldFailAssertionWithError(invalidKeyError)

            _ = try await stripeAttest.assert()
            XCTFail("Should not succeed")
        } catch {
            XCTAssertEqual(error as! StripeAttest.AttestationError, StripeAttest.AttestationError.shouldNotAttest)
        }
    }

    func testNoPublishableKey() async {
        await stripeAttest.apiClient!.publishableKey = nil
        do {
            // Create and attest a key
            try await stripeAttest.attest()
            XCTFail("Should not succeed")
        } catch {
            XCTAssertEqual(error as! StripeAttest.AttestationError, StripeAttest.AttestationError.noPublishableKey)
        }
    }

    func testAssertionsNotRequiredInTestMode() async {
        // Configure a test merchant PK:
        await stripeAttest.apiClient!.publishableKey = "pk_test_abc123"
        // And reset the attestation tracking:
        await UserDefaults.standard.removeObject(forKey: self.stripeAttest.defaultsKeyForSetting(.dailyAttemptCount))
        await UserDefaults.standard.removeObject(forKey: self.stripeAttest.defaultsKeyForSetting(.firstAttemptToday))
        // Fail the assertion, which will cause us to try to re-attest the key, but then the
        // assertions still won't work, so we'll send the testmode data instead.
        let invalidKeyError = NSError(domain: DCErrorDomain, code: DCError.invalidKey.rawValue, userInfo: nil)
        await mockAttestService.setShouldFailAssertionWithError(invalidKeyError)
        let assertionHandle = try! await stripeAttest.assert()
        XCTAssertEqual(assertionHandle.assertion.keyID, "TestKeyID")
    }

    func testConcurrentAssertionsOccurSequentially() async {
        let iterations = 500
        try! await withThrowingTaskGroup(of: Void.self) { group in
            for _ in 0..<iterations {
                group.addTask {
                    let assertionHandle = try! await self.stripeAttest.assert()
                    // Check the assertion against the mock backend (which will enforce that the counter value has incremented since the last assertion)
                    try! await self.mockAttestBackend.assertionTest(assertion: assertionHandle.assertion)
                    // Then complete the assertion
                    assertionHandle.complete()
                }
            }
            try await group.waitForAll()
        }
    }

    func testConcurrentFailedAssertionsDoNotBlock() async {
        let iterations = 5
        let unknownError = NSError(domain: "test", code: 0, userInfo: nil)
        let expectation = self.expectation(description: "Wait for assertions")
        expectation.expectedFulfillmentCount = iterations
        await mockAttestService.setShouldFailAssertionWithError(unknownError)
        // Make sure we correctly continue the assertionWaiters continuations if an error occurs
        Task {
            try! await withThrowingTaskGroup(of: Void.self) { group in
                for _ in 0..<iterations {
                    group.addTask {
                        do {
                            _ = try await self.stripeAttest.assert()
                            XCTFail("Should not succeed")
                        } catch {
                            XCTAssertEqual(error as NSError, unknownError)
                            expectation.fulfill()
                        }
                    }
                }
                try await group.waitForAll()
            }
        }
        await fulfillment(of: [expectation], timeout: 1)
    }
}
