//
//  StripeAttestTest.swift
//  StripeCore
//

import DeviceCheck
@testable @_spi(STP) import StripeCore
import XCTest

class StripeAttestTest: XCTestCase {
    var mockAttestService: MockAppAttestService!
    var mockAttestBackend: MockAttestBackend!
    var stripeAttest: StripeAttest!

    override func setUp() {
        self.mockAttestBackend = MockAttestBackend()
        self.mockAttestService = MockAppAttestService()
        self.stripeAttest = StripeAttest(appAttestService: mockAttestService, appAttestBackend: mockAttestBackend, apiClient: .shared)

        let expectation = self.expectation(description: "Wait for setup")
        // Reset storage
        Task { @MainActor in
            await UserDefaults.standard.removeObject(forKey: self.stripeAttest.defaultsKeyForSetting(.lastAttestedDate))
            await stripeAttest.resetKey()
            expectation.fulfill()
        }
        waitForExpectations(timeout: 5)
    }

    func testAppAttestService() async {
        try! await stripeAttest.attest()
        let assertionResponse = try! await stripeAttest.assert()
        try! await self.mockAttestBackend.assertionTest(assertion: assertionResponse)
    }

    func testCanAssertWithoutAttestation() async {
        let assertionResponse = try! await stripeAttest.assert()
        try! await self.mockAttestBackend.assertionTest(assertion: assertionResponse)
    }

    func testCanOnlyAttestOncePerDayInProd() async {
        // Create and attest a key
        try! await stripeAttest.attest()
        let invalidKeyError = NSError(domain: DCErrorDomain, code: DCError.invalidKey.rawValue, userInfo: nil)
        // But fail the assertion, causing the key to be reset
        await mockAttestService.setShouldFailAssertionWithError(invalidKeyError)
        do {
            _ = try await stripeAttest.assert()
            XCTFail("Should not succeed")
        } catch {
            // Should get a rate limiting error when we try to generate the second key:
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
            // But it's an old key, so we'll be allowed to attest a new one
            await UserDefaults.standard.set(Date.distantPast, forKey: self.stripeAttest.defaultsKeyForSetting(.lastAttestedDate))
            // Always fail the assertions and don't remember attestations:
            let invalidKeyError = NSError(domain: DCErrorDomain, code: DCError.invalidKey.rawValue, userInfo: nil)
            await mockAttestService.setShouldFailAssertionWithError(invalidKeyError)

            _ = try await stripeAttest.assert()
            XCTFail("Should not succeed")
        } catch {
            XCTAssertEqual(error as! StripeAttest.AttestationError, StripeAttest.AttestationError.shouldNotAttest)
        }
    }
    
    func testConcurrentAssertionsAndAttestations() async {
        let iterations = 500
        try! await withThrowingTaskGroup(of: Void.self) { group in
            for _ in 0..<iterations {
                group.addTask {
                    try await self.stripeAttest.assert()
                }
            }
            try await group.waitForAll()
        }
    }
    func testConcurrentAttestations() async {
        let iterations = 500
        try! await withThrowingTaskGroup(of: Void.self) { group in
            for _ in 0..<iterations {
                group.addTask {
                    try await self.stripeAttest.attest()
                }
            }
            try await group.waitForAll()
        }
    }
}
