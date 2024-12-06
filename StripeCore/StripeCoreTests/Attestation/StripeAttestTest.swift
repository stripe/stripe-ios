//
//  StripeAttestTest.swift
//  StripeCore
//

@testable @_spi(STP) import StripeCore
import XCTest
import DeviceCheck

class StripeAttestTest: XCTestCase {
    var mockAttestService: MockAppAttestService!
    var mockAttestBackend: MockAttestBackend!
    var stripeAttest: StripeAttest!
    
    override func setUp() {
        self.mockAttestBackend = MockAttestBackend()
        self.mockAttestService = MockAppAttestService()
        self.stripeAttest = StripeAttest(appAttestService: mockAttestService, appAttestBackend: mockAttestBackend)

        // Reset storage
        UserDefaults.standard.removeObject(forKey: "STPAttestKeyLastGenerated")
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

    func testCanOnlyGenerateOncePerDay() async {
        // Create and attest a key
        try! await stripeAttest.attest()
        let invalidKeyError = NSError(domain: DCErrorDomain, code: DCError.invalidKey.rawValue, userInfo: nil)
        // But fail the assertion, causing the key to be reset, and have the second attestation fail too:
        mockAttestService.shouldFailAssertionWithError = invalidKeyError
        mockAttestService.shouldFailAttestationWithError = invalidKeyError
        do {
            let _ = try await stripeAttest.assert()
            XCTFail("Should not succeed")
        } catch {
            XCTAssertEqual(error as NSError, invalidKeyError)
        }
        
        // Fix the errors:
        mockAttestService.shouldFailAssertionWithError = nil
        mockAttestService.shouldFailAttestationWithError = nil
        // Now try again:
        do {
            try await stripeAttest.attest()
            XCTFail("Should not succeed")
        } catch {
            // Should get a rate limiting error
            XCTAssertEqual(error as! StripeAttest.AttestationError, StripeAttest.AttestationError.keygenRateLimitExceeded)
        }
    }
    
    func testAssertionGivesUpAfterMultipleTries() async {
        do {
            // Create and attest a key
            try! await stripeAttest.attest()
            // But it's an old key, so we'll be allowed to generate a new one
            UserDefaults.standard.set(Date.distantPast, forKey: "STPAttestKeyLastGenerated")
            // Always fail the assertions:
            let invalidKeyError = NSError(domain: DCErrorDomain, code: DCError.invalidKey.rawValue, userInfo: nil)
            mockAttestService.shouldFailAssertionWithError = invalidKeyError

            _ = try await stripeAttest.assert()
            XCTFail("Should not succeed")
        } catch {
            XCTAssertEqual(error as! StripeAttest.AttestationError, StripeAttest.AttestationError.secondAssertionFailureAfterRetryingAttestation)
        }
    }
}
