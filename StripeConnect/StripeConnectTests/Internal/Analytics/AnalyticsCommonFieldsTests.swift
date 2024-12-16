//
//  AnalyticsCommonFieldsTests.swift
//  StripeConnect
//
//  Created by Mel Ludowise on 11/7/24.
//

@testable import StripeConnect
@_spi(DashboardOnly) import StripeCore
import XCTest

class AnalyticsCommonFieldsTests: XCTestCase {
    let mockUUID = UUID(uuidString: "eb9d1d0a-2adb-4b5e-9e5c-aebd5b70810b")!

    func testInitFromUserKey() {
        let client = STPAPIClient()
        client.publishableKey = "uk_123"
        client.userKeyLiveMode = false
        client.stripeAccount = "acct_123"

        let fields = ComponentAnalyticsClient.CommonFields(
            params: .init(component: .payouts, apiClient: client, publicKeyOverride: nil),
            componentInstance: mockUUID
        )

        XCTAssertNil(fields.publishableKey)
        XCTAssertEqual(fields.platformId, "acct_123")
        XCTAssertEqual(fields.merchantId, "acct_123")
        XCTAssertEqual(fields.livemode, false)
        XCTAssertEqual(fields.component, .payouts)
        XCTAssertEqual(fields.componentInstance, mockUUID)
    }
    
    func testPublicKeyOverride() {
        let client = STPAPIClient()
        client.publishableKey = "uk_123"

        let fields = ComponentAnalyticsClient.CommonFields(
            params: .init(component: .payouts, apiClient: client, publicKeyOverride: "pk_123"),
            componentInstance: mockUUID
        )

        XCTAssertEqual(fields.publishableKey, "pk_123")
    }

    func testInitFromPublicKey() {
        let client = STPAPIClient()
        client.publishableKey = "pk_123"
        client.userKeyLiveMode = false
        client.stripeAccount = "acct_123"

        let fields = ComponentAnalyticsClient.CommonFields(
            params: .init(component: .payouts, apiClient: client, publicKeyOverride: nil),
            componentInstance: mockUUID
        )

        XCTAssertEqual(fields.publishableKey, "pk_123")
        XCTAssertNil(fields.platformId)
        XCTAssertNil(fields.merchantId)
        XCTAssertNil(fields.livemode)
        XCTAssertEqual(fields.component, .payouts)
        XCTAssertEqual(fields.componentInstance, mockUUID)
    }

    func testSecretKeyRedacted() {
        let client = STPAPIClient()
        client.publishableKey = "sk_123"

        let fields = ComponentAnalyticsClient.CommonFields(
            params: .init(component: .payouts, apiClient: client, publicKeyOverride: nil),
            componentInstance: mockUUID
        )

        XCTAssertEqual(fields.publishableKey, "[REDACTED_LIVE_KEY]")
    }
}
