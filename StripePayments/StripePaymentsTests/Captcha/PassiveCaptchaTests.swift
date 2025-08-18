//
//  PassiveCaptchaTests.swift
//  StripeCoreTests
//
//  Created by Assistant on 8/8/25.
//

@testable import StripeCore
import XCTest

class PassiveCaptchaTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Reset the override to nil before each test
        PassiveCaptcha._overrideIsTestEnvironment = nil
    }

    override func tearDown() {
        // Clean up after each test
        PassiveCaptcha._overrideIsTestEnvironment = nil
        super.tearDown()
    }

    // MARK: - Test Environment Detection

    func testFetchPassiveHCaptchaToken_inTestEnvironment_returnsNilImmediately() {
        // Given: Normal test environment (should be detected automatically)
        let passiveCaptcha = PassiveCaptcha(siteKey: "test_site_key", rqdata: "test_data")
        let expectation = self.expectation(description: "Completion called")
        var result: String?

        // When: Call fetchPassiveHCaptchaToken
        PassiveCaptcha.fetchPassiveHCaptchaToken(passiveCaptcha: passiveCaptcha) { token in
            result = token
            expectation.fulfill()
        }

        // Then: Should return nil immediately (within 1 second)
        waitForExpectations(timeout: 1.0)
        XCTAssertNil(result, "Should return nil in test environment")
    }

    func testFetchPassiveHCaptchaToken_withNilPassiveCaptcha_returnsNil() {
        // Given: nil PassiveCaptcha and overridden test environment detection
        PassiveCaptcha._overrideIsTestEnvironment = false
        let expectation = self.expectation(description: "Completion called")
        var result: String?

        // When: Call fetchPassiveHCaptchaToken with nil
        PassiveCaptcha.fetchPassiveHCaptchaToken(passiveCaptcha: nil) { token in
            result = token
            expectation.fulfill()
        }

        // Then: Should return nil immediately
        waitForExpectations(timeout: 1.0)
        XCTAssertNil(result, "Should return nil for nil PassiveCaptcha")
    }

    // MARK: - Test Environment Override

    func testFetchPassiveHCaptchaToken_withTestEnvironmentOverrideFalse_allowsHCaptchaCreation() {
        // Given: Override test environment detection to false
        PassiveCaptcha._overrideIsTestEnvironment = false
        let passiveCaptcha = PassiveCaptcha(siteKey: "invalid_key", rqdata: nil)
        let expectation = self.expectation(description: "Completion called")
        var result: String?

        // When: Call fetchPassiveHCaptchaToken
        PassiveCaptcha.fetchPassiveHCaptchaToken(passiveCaptcha: passiveCaptcha) { token in
            result = token
            expectation.fulfill()
        }

        // Then: Should attempt to create HCaptcha (will fail with invalid key, but won't return due to test detection)
        waitForExpectations(timeout: 2.0)
        XCTAssertNil(result, "Should return nil due to invalid HCaptcha key")
    }

    func testFetchPassiveHCaptchaToken_withTestEnvironmentOverrideTrue_returnsNilImmediately() {
        // Given: Override test environment detection to true
        PassiveCaptcha._overrideIsTestEnvironment = true
        let passiveCaptcha = PassiveCaptcha(siteKey: "test_site_key", rqdata: "test_data")
        let expectation = self.expectation(description: "Completion called")
        var result: String?

        // When: Call fetchPassiveHCaptchaToken
        PassiveCaptcha.fetchPassiveHCaptchaToken(passiveCaptcha: passiveCaptcha) { token in
            result = token
            expectation.fulfill()
        }

        // Then: Should return nil immediately due to override
        waitForExpectations(timeout: 1.0)
        XCTAssertNil(result, "Should return nil when test environment is overridden to true")
    }

    // MARK: - Timeout Behavior (when HCaptcha hangs)

    func testFetchPassiveHCaptchaToken_simulateHangingHCaptcha() {
        // Given: Override test environment to false to allow HCaptcha creation
        PassiveCaptcha._overrideIsTestEnvironment = false

        // Use a localhost URL that should cause HCaptcha to hang/fail
        let passiveCaptcha = PassiveCaptcha(siteKey: "10000000-ffff-ffff-ffff-000000000001", rqdata: nil)
        let expectation = self.expectation(description: "Completion called")
        var result: String?
        var completionTime: Date?
        let startTime = Date()

        // When: Call fetchPassiveHCaptchaToken (should hang and eventually timeout)
        PassiveCaptcha.fetchPassiveHCaptchaToken(passiveCaptcha: passiveCaptcha) { token in
            result = token
            completionTime = Date()
            expectation.fulfill()
        }

        // Then: Should eventually return nil (allow more time for real HCaptcha attempt)
        waitForExpectations(timeout: 15.0)
        XCTAssertNil(result, "Should return nil when HCaptcha hangs")

        if let completionTime = completionTime {
            let elapsedTime = completionTime.timeIntervalSince(startTime)
            // Should take some time (either due to quick failure or timeout)
            XCTAssertGreaterThan(elapsedTime, 0.1, "Should take some time to complete")
        }
    }

    func testFetchPassiveHCaptchaToken_timeoutSendsAnalytic() {
        // Given: Override test environment to false to allow HCaptcha creation and clear analytics
        PassiveCaptcha._overrideIsTestEnvironment = false
        STPAnalyticsClient.sharedClient._testLogHistory = []

        // Use a localhost URL that should cause HCaptcha to hang/fail and trigger timeout
        let passiveCaptcha = PassiveCaptcha(siteKey: "10000000-ffff-ffff-ffff-000000000001", rqdata: nil)
        let expectation = self.expectation(description: "Completion called")
        var result: String?
        let startTime = Date()

        // When: Call fetchPassiveHCaptchaToken (should timeout and send analytic)
        PassiveCaptcha.fetchPassiveHCaptchaToken(passiveCaptcha: passiveCaptcha) { token in
            result = token
            expectation.fulfill()
        }

        // Then: Should eventually return nil and log timeout analytic
        waitForExpectations(timeout: 12.0) // Wait a bit longer than our 10 second timeout
        XCTAssertNil(result, "Should return nil when HCaptcha times out")

        // Verify analytic was logged
        let timeoutAnalytics = STPAnalyticsClient.sharedClient._testLogHistory.filter {
            ($0["event"] as? String) == STPAnalyticEvent.passiveCaptchaTimeout.rawValue
        }
        XCTAssertGreaterThanOrEqual(timeoutAnalytics.count, 1, "Should log timeout analytic when captcha times out")

        let elapsedTime = Date().timeIntervalSince(startTime)
        // Should timeout around 10 seconds
        XCTAssertGreaterThanOrEqual(elapsedTime, 10.0, "Should timeout after approximately 10 seconds")
        XCTAssertLessThan(elapsedTime, 12.0, "Should not take much longer than 10 seconds")
    }

    // MARK: - PassiveCaptcha Creation Tests

    func testPassiveCaptchaCreation() {
        // Given: Valid parameters
        let siteKey = "test_site_key"
        let rqdata = "test_rqdata"

        // When: Create PassiveCaptcha
        let passiveCaptcha = PassiveCaptcha(siteKey: siteKey, rqdata: rqdata)

        // Then: Should have correct values
        XCTAssertEqual(passiveCaptcha.siteKey, siteKey)
        XCTAssertEqual(passiveCaptcha.rqdata, rqdata)
    }

    func testPassiveCaptchaCreation_withNilRqdata() {
        // Given: Valid site key but nil rqdata
        let siteKey = "test_site_key"

        // When: Create PassiveCaptcha
        let passiveCaptcha = PassiveCaptcha(siteKey: siteKey, rqdata: nil)

        // Then: Should have correct values
        XCTAssertEqual(passiveCaptcha.siteKey, siteKey)
        XCTAssertNil(passiveCaptcha.rqdata)
    }

    // MARK: - Integration Test (demonstrating real-world usage)

    func testFetchPassiveHCaptchaToken_integrationExample() {
        // This test demonstrates how the method behaves in a real test environment
        let passiveCaptcha = PassiveCaptcha(siteKey: "20000000-ffff-ffff-ffff-000000000002", rqdata: nil)
        let expectation = self.expectation(description: "Completion called")
        var completedSuccessfully = false

        PassiveCaptcha.fetchPassiveHCaptchaToken(passiveCaptcha: passiveCaptcha) { token in
            // In test environment, this should be nil
            XCTAssertNil(token, "Should return nil in test environment")
            completedSuccessfully = true
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1.0)
        XCTAssertTrue(completedSuccessfully, "Completion handler should be called")
    }
}
