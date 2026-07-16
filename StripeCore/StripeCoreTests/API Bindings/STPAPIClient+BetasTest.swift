//
//  STPAPIClient+BetasTest.swift
//  StripeCoreTests
//
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

@_spi(STP) import StripeCore
import XCTest

class STPAPIClient_BetasTest: XCTestCase {
    func testBetasAreAppendedToStripeVersionHeader() {
        let apiClient = STPAPIClient(publishableKey: "pk_test_123")
        apiClient.betas = ["alipay_beta=v1"]

        let request = apiClient.configuredRequest(for: URL(string: "https://api.stripe.com/v1/tokens")!)
        let stripeVersion = request.value(forHTTPHeaderField: "Stripe-Version")

        XCTAssertNotNil(stripeVersion)
        XCTAssertTrue(stripeVersion?.contains("alipay_beta=v1") ?? false)
    }

    func testMultipleBetasAreAppendedToStripeVersionHeader() {
        let apiClient = STPAPIClient(publishableKey: "pk_test_123")
        apiClient.betas = ["alipay_beta=v1", "some_other_beta=v2"]

        let request = apiClient.configuredRequest(for: URL(string: "https://api.stripe.com/v1/tokens")!)
        let stripeVersion = request.value(forHTTPHeaderField: "Stripe-Version")

        XCTAssertNotNil(stripeVersion)
        XCTAssertTrue(stripeVersion?.contains("alipay_beta=v1") ?? false)
        XCTAssertTrue(stripeVersion?.contains("some_other_beta=v2") ?? false)
    }

    func testNoBetasByDefault() {
        let apiClient = STPAPIClient(publishableKey: "pk_test_123")

        XCTAssertTrue(apiClient.betas.isEmpty)
    }
}
