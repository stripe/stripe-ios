//
//  STPAPIClientTest.swift
//  StripeiOS Tests
//
//  Created by Jack Flintermann on 12/19/14.
//  Copyright (c) 2014 Stripe, Inc. All rights reserved.
//

import XCTest

@testable@_spi(STP) import Stripe
@testable@_spi(STP) import StripeApplePay
@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePayments
@testable@_spi(STP) import StripePaymentSheet
@testable@_spi(STP) import StripePaymentsUI

class STPAPIClientTest: XCTestCase {
    func testSharedClient() {
        XCTAssert(STPAPIClient.shared === STPAPIClient.shared)
    }

    func testSetDefaultPublishableKey() {
        let clientInitializedBefore = STPAPIClient()
        StripeAPI.defaultPublishableKey = "test"
        let clientInitializedAfter = STPAPIClient()
        let sharedClient = STPAPIClient.shared
        XCTAssertEqual(clientInitializedBefore.publishableKey, "test")
        XCTAssertEqual(clientInitializedAfter.publishableKey, "test")

        // Setting the STPAPIClient instance overrides Stripe.defaultPublishableKey...
        sharedClient.publishableKey = "test2"
        XCTAssertEqual(sharedClient.publishableKey, "test2")

        // ...while Stripe.defaultPublishableKey remains the same
        XCTAssertEqual(StripeAPI.defaultPublishableKey, "test")
    }

    func testInitWithPublishableKey() {
        let sut = STPAPIClient(publishableKey: "pk_foo")
        let authHeader = sut.configuredRequest(
            for: URL(string: "https://www.stripe.com")!,
            additionalHeaders: [:]
        ).allHTTPHeaderFields?["Authorization"]
        XCTAssertEqual(authHeader, "Bearer pk_foo")
    }

    func testSetPublishableKey() {
        let sut = STPAPIClient(publishableKey: "pk_foo")
        var authHeader = sut.configuredRequest(
            for: URL(string: "https://www.stripe.com")!,
            additionalHeaders: [:]
        ).allHTTPHeaderFields?["Authorization"]
        XCTAssertEqual(authHeader, "Bearer pk_foo")
        sut.publishableKey = "pk_bar"
        authHeader =
            sut.configuredRequest(
                for: URL(string: "https://www.stripe.com")!,
                additionalHeaders: [:]
            )
            .allHTTPHeaderFields?["Authorization"]
        XCTAssertEqual(authHeader, "Bearer pk_bar")
    }

    func testEphemeralKeyOverwritesHeader() {
        let sut = STPAPIClient(publishableKey: "pk_foo")
        let ephemeralKey = STPFixtures.ephemeralKey()
        let additionalHeaders = sut.authorizationHeader(using: ephemeralKey)
        let authHeader = sut.configuredRequest(
            for: URL(string: "https://www.stripe.com")!,
            additionalHeaders: additionalHeaders
        ).allHTTPHeaderFields?["Authorization"]
        XCTAssertEqual(authHeader, "Bearer " + (ephemeralKey.secret))
    }

    func testSetStripeAccount() {
        let sut = STPAPIClient(publishableKey: "pk_foo")
        var accountHeader = sut.configuredRequest(
            for: URL(string: "https://www.stripe.com")!,
            additionalHeaders: [:]
        ).allHTTPHeaderFields?["Stripe-Account"]
        XCTAssertNil(accountHeader)
        sut.stripeAccount = "acct_123"
        accountHeader =
            sut.configuredRequest(
                for: URL(string: "https://www.stripe.com")!,
                additionalHeaders: [:]
            )
            .allHTTPHeaderFields?["Stripe-Account"]
        XCTAssertEqual(accountHeader, "acct_123")
    }

    private struct MockUAUsageClass: STPAnalyticsProtocol {
        static let stp_analyticsIdentifier = "MockUAUsageClass"
    }

    func testPaymentUserAgent() {
        STPAnalyticsClient.sharedClient.productUsage = .init()
        STPAnalyticsClient.sharedClient.addClass(toProductUsageIfNecessary: MockUAUsageClass.self)
        var params: [String: Any] = [:]
        params = STPAPIClient.paramsAddingPaymentUserAgent(params)
        XCTAssertEqual(params["payment_user_agent"] as! String, "stripe-ios/\(StripeAPIConfiguration.STPSDKVersion); variant.paymentsheet; MockUAUsageClass")

        params = STPAPIClient.paramsAddingPaymentUserAgent(params, additionalValues: ["foo"])
        XCTAssertEqual(params["payment_user_agent"] as! String, "stripe-ios/\(StripeAPIConfiguration.STPSDKVersion); variant.paymentsheet; MockUAUsageClass; foo")
    }

    func testClientAttributionMetadata() {
        AnalyticsHelper.shared.generateSessionID()
        var params: [String: Any] = [:]
        params = STPAPIClient.paramsAddingClientAttributionMetadata(params)
        let clientAttributionMetadata = params["client_attribution_metadata"] as? [String: String]
        XCTAssertEqual(clientAttributionMetadata?["client_session_id"], AnalyticsHelper.shared.sessionID)
        XCTAssertEqual(clientAttributionMetadata?["merchant_integration_source"], "elements")
        XCTAssertEqual(clientAttributionMetadata?["merchant_integration_subtype"], "mobile")
        XCTAssertEqual(clientAttributionMetadata?["merchant_integration_version"], "stripe-ios/\(StripeAPIConfiguration.STPSDKVersion)")
    }

    func testSetAppInfo() {
        let sut = STPAPIClient(publishableKey: "pk_foo")
        sut.appInfo = STPAppInfo(
            name: "MyAwesomeLibrary",
            partnerId: "pp_partner_1234",
            version: "1.2.34",
            url: "https://myawesomelibrary.info"
        )
        let userAgentHeader = sut.configuredRequest(
            for: URL(string: "https://www.stripe.com")!,
            additionalHeaders: [:]
        ).allHTTPHeaderFields?["X-Stripe-User-Agent"]
        var userAgentHeaderDict: [AnyHashable: Any]?
        do {
            if let data = userAgentHeader?.data(using: .utf8) {
                userAgentHeaderDict =
                    try JSONSerialization.jsonObject(with: data, options: []) as? [AnyHashable: Any]
            }
        } catch {
        }
        XCTAssertEqual(userAgentHeaderDict?["name"] as! String, "MyAwesomeLibrary")
        XCTAssertEqual(userAgentHeaderDict?["partner_id"] as! String, "pp_partner_1234")
        XCTAssertEqual(userAgentHeaderDict?["version"] as! String, "1.2.34")
        XCTAssertEqual(userAgentHeaderDict?["url"] as! String, "https://myawesomelibrary.info")
    }
}
