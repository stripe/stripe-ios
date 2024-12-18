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

        // Reset storage
        UserDefaults.standard.removeObject(forKey: StripeAttest.DefaultsKeys.lastAttestedDate.rawValue)
        stripeAttest.resetKey()
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

    func testCanOnlyAttestOncePerDay() async {
        // Create and attest a key
        try! await stripeAttest.attest()
        let invalidKeyError = NSError(domain: DCErrorDomain, code: DCError.invalidKey.rawValue, userInfo: nil)
        // But fail the assertion, causing the key to be reset
        mockAttestService.shouldFailAssertionWithError = invalidKeyError
        do {
            _ = try await stripeAttest.assert()
            XCTFail("Should not succeed")
        } catch {
            // Should get a rate limiting error when we try to generate the second key:
            XCTAssertEqual(error as! StripeAttest.AttestationError, StripeAttest.AttestationError.attestationRateLimitExceeded)
        }
    }

    func testAssertionDoesNotAttestIfAlreadyAttested() async {
        do {
            // Create and attest a key
            try! await stripeAttest.attest()
            // But it's an old key, so we'll be allowed to attest a new one
            UserDefaults.standard.set(Date.distantPast, forKey: StripeAttest.DefaultsKeys.lastAttestedDate.rawValue)
            // Always fail the assertions and don't remember attestations:
            let invalidKeyError = NSError(domain: DCErrorDomain, code: DCError.invalidKey.rawValue, userInfo: nil)
            mockAttestService.shouldFailAssertionWithError = invalidKeyError

            _ = try await stripeAttest.assert()
            XCTFail("Should not succeed")
        } catch {
            XCTAssertEqual(error as! StripeAttest.AttestationError, StripeAttest.AttestationError.shouldNotAttest)
        }
    }
}
