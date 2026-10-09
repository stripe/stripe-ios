//
//  STPWebMessageSourcePolicyTests.swift
//  StripeCoreTests
//

@_spi(STP) @testable import StripeCore
import XCTest

final class STPWebMessageSourcePolicyTests: XCTestCase {
    private final class Source {}

    func testAuthorizesExactExpectedSourceAndDefaultHTTPSPort() {
        let source = Source()
        let policy = policy(source: source, urls: ["https://connect-js.stripe.com"])

        XCTAssertTrue(policy.isAuthorized(source: source, scheme: "https", host: "connect-js.stripe.com", port: 443))
        XCTAssertTrue(policy.isAuthorized(source: source, scheme: "https", host: "connect-js.stripe.com", port: 0))
    }

    func testRejectsNilExpiredAndMismatchedSources() {
        let source = Source()
        let policy = policy(source: source, urls: ["https://connect-js.stripe.com"])
        XCTAssertFalse(policy.isAuthorized(source: nil, scheme: "https", host: "connect-js.stripe.com", port: 443))
        XCTAssertFalse(policy.isAuthorized(source: Source(), scheme: "https", host: "connect-js.stripe.com", port: 443))

        weak var expiredSource: Source?
        let expiredPolicy: STPWebMessageSourcePolicy = {
            let ephemeralSource = Source()
            expiredSource = ephemeralSource
            return self.policy(source: ephemeralSource, urls: ["https://connect-js.stripe.com"])
        }()
        XCTAssertNil(expiredSource)
        XCTAssertFalse(expiredPolicy.isAuthorized(source: source, scheme: "https", host: "connect-js.stripe.com", port: 443))
    }

    func testNormalizesSchemeHostAndDefaultPortButRejectsLookalikes() {
        let source = Source()
        let policy = policy(source: source, urls: ["https://Connect-JS.Stripe.com/path?query=value#fragment"])

        XCTAssertTrue(policy.isAuthorized(source: source, scheme: "HTTPS", host: "CONNECT-JS.STRIPE.COM", port: 0))
        XCTAssertFalse(policy.isAuthorized(source: source, scheme: "http", host: "connect-js.stripe.com", port: 443))
        XCTAssertFalse(policy.isAuthorized(source: source, scheme: "https", host: "connect-js.stripe.com.evil.test", port: 443))
        XCTAssertFalse(policy.isAuthorized(source: source, scheme: "https", host: "connect-js.stripe.com.attacker.test", port: 443))
        XCTAssertFalse(policy.isAuthorized(source: source, scheme: "https", host: "connect.stripe.com", port: 443))
        XCTAssertFalse(policy.isAuthorized(source: source, scheme: "https", host: "", port: 443))
        XCTAssertFalse(policy.isAuthorized(source: source, scheme: "https", host: "connect-js.stripe.com", port: 8443))
        XCTAssertFalse(policy.isAuthorized(source: source, scheme: "https", host: "connect-js.stripe.com", port: -1))
        XCTAssertFalse(policy.isAuthorized(source: source, scheme: "https", host: "connect-js.stripe.com", port: 65_536))
    }

    func testSupportsExplicitNonDefaultPortOnlyAtThatPort() {
        let source = Source()
        let policy = policy(source: source, urls: ["https://connect-js.stripe.com:8443/path"])

        XCTAssertTrue(policy.isAuthorized(source: source, scheme: "https", host: "connect-js.stripe.com", port: 8443))
        XCTAssertFalse(policy.isAuthorized(source: source, scheme: "https", host: "connect-js.stripe.com", port: 443))
        XCTAssertFalse(policy.isAuthorized(source: source, scheme: "https", host: "connect-js.stripe.com", port: 0))
    }

    func testRejectsEmptyAndInvalidConfigurationListsAsAWhole() {
        let source = Source()
        let emptyPolicy = policy(source: source, urls: [])
        XCTAssertFalse(emptyPolicy.isAuthorized(source: source, scheme: "https", host: "connect-js.stripe.com", port: 443))

        let customOverridePolicy = policy(source: source, urls: ["https://override.example.test:8443"])
        XCTAssertFalse(customOverridePolicy.isAuthorized(source: source, scheme: "https", host: "connect-js.stripe.com", port: 443))

        let invalidURLs = [
            "http://connect-js.stripe.com",
            "https:///missing-host",
            "https://connect-js.stripe.com:0",
        ]
        for invalidURL in invalidURLs {
            let mixedPolicy = policy(source: source, urls: ["https://connect-js.stripe.com", invalidURL])
            XCTAssertFalse(mixedPolicy.isAuthorized(source: source, scheme: "https", host: "connect-js.stripe.com", port: 443), invalidURL)
        }
    }

    private func policy(source: AnyObject, urls: [String]) -> STPWebMessageSourcePolicy {
        STPWebMessageSourcePolicy(expectedSource: source, allowedOriginURLs: urls.map { URL(string: $0)! })
    }
}
