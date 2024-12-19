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
        let apiClient = STPAPIClient(publishableKey: "pk_live_abc123")
        self.mockAttestBackend = MockAttestBackend()
        self.mockAttestService = MockAppAttestService()
        self.stripeAttest = StripeAttest(appAttestService: mockAttestService, appAttestBackend: mockAttestBackend, apiClient: apiClient)

        // Reset storage
        UserDefaults.standard.removeObject(forKey: self.stripeAttest.defaultsKeyForSetting(.lastAttestedDate))
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

    func testCanOnlyAttestOncePerDayInProd() async {
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

    func testCanAttestAsMuchAsNeededInDev() async {
        // Create and attest a key in the dev environment
        mockAttestService.attestationUsingDevelopmentEnvironment = true
        try! await stripeAttest.attest()
        let invalidKeyError = NSError(domain: DCErrorDomain, code: DCError.invalidKey.rawValue, userInfo: nil)
        // But fail the assertion, which will cause us to try to re-attest the key
        mockAttestService.shouldFailAssertionWithError = invalidKeyError
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
            UserDefaults.standard.set(Date.distantPast, forKey: self.stripeAttest.defaultsKeyForSetting(.lastAttestedDate))
            // Always fail the assertions and don't remember attestations:
            let invalidKeyError = NSError(domain: DCErrorDomain, code: DCError.invalidKey.rawValue, userInfo: nil)
            mockAttestService.shouldFailAssertionWithError = invalidKeyError

            _ = try await stripeAttest.assert()
            XCTFail("Should not succeed")
        } catch {
            XCTAssertEqual(error as! StripeAttest.AttestationError, StripeAttest.AttestationError.shouldNotAttest)
        }
    }

    func testNoPublishableKey() async {
        stripeAttest.apiClient.publishableKey = nil
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
        stripeAttest.apiClient.publishableKey = "pk_test_abc123"
        // And reset the last attestation date:
        UserDefaults.standard.removeObject(forKey: self.stripeAttest.defaultsKeyForSetting(.lastAttestedDate))
        // Fail the assertion, which will cause us to try to re-attest the key, but then the
        // assertions still won't work, so we'll send the testmode data instead.
        let invalidKeyError = NSError(domain: DCErrorDomain, code: DCError.invalidKey.rawValue, userInfo: nil)
        mockAttestService.shouldFailAssertionWithError = invalidKeyError
        let assertion = try! await stripeAttest.assert()
        XCTAssertEqual(assertion.keyID, "TestKeyID")
    }
}
