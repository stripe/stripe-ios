//
//  STPAPIClient+UserAgentTest.swift
//  StripeCoreTests
//
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

@_spi(InternalOnlyAPI) import StripeCore
import XCTest

class STPAPIClient_UserAgentTest: XCTestCase {
    override func tearDown() {
        STPAPIClient.userAgentSDKVersionOverride = nil
        super.tearDown()
    }

    func testBindingsVersionDefaultsToSDKVersion() throws {
        // Given no override
        let apiClient = STPAPIClient(publishableKey: "pk_test_123")

        // When a request is configured
        let version = try bindingsVersion(apiClient)

        // Then it reports the SDK's version
        XCTAssertEqual(version, STPAPIClient.STPSDKVersion)
    }

    func testBindingsVersionUsesOverride() throws {
        // Given an override
        STPAPIClient.userAgentSDKVersionOverride = "25.0.0"
        let apiClient = STPAPIClient(publishableKey: "pk_test_123")

        // When a request is configured
        let version = try bindingsVersion(apiClient)

        // Then it reports the override
        XCTAssertEqual(version, "25.0.0")
    }

    private func bindingsVersion(_ apiClient: STPAPIClient) throws -> String? {
        let request = apiClient.configuredRequest(for: URL(string: "https://api.stripe.com/v1/tokens")!)
        let header = try XCTUnwrap(request.value(forHTTPHeaderField: "X-Stripe-User-Agent"))
        let details = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(header.utf8)) as? [String: Any])
        return details["bindings_version"] as? String
    }
}
