//
//  ConnectJSURLParamsTests.swift
//  StripeConnectTests
//
//  Created by Mel Ludowise on 9/20/24.
//

@testable import StripeConnect
@_spi(STP) @_spi(DashboardOnly) import StripeCore
import XCTest

class ConnectJSURLParamsTests: XCTestCase {
    let apiClient = STPAPIClient()

    override func setUp() {
        super.setUp()
        apiClient.userKeyLiveMode = false
        apiClient.stripeAccount = "acct_123"
    }

    func testInitFromApiClient_publicKey() {
        apiClient.publishableKey = "pk_1234"

        let urlParams = ConnectJSURLParams(component: .onboarding, apiClient: apiClient, publicKeyOverride: nil)
        XCTAssertEqual(urlParams.publicKey, "pk_1234")
        XCTAssertNil(urlParams.apiKeyOverride)
        XCTAssertNil(urlParams.merchantIdOverride)
        XCTAssertNil(urlParams.platformIdOverride)
        XCTAssertNil(urlParams.livemodeOverride)
    }
    
    func testInitFromApiClient_publicKeyOverride() {
        apiClient.publishableKey = "uk_1234"

        let urlParams = ConnectJSURLParams(component: .onboarding, apiClient: apiClient, publicKeyOverride: "pk_4567")
        XCTAssertEqual(urlParams.publicKey, "pk_4567")
    }

    func testInitFromApiClient_userKeyIncludesOverrideParams() {
        apiClient.publishableKey = "uk_1234"

        let urlParams = ConnectJSURLParams(component: .onboarding, apiClient: apiClient, publicKeyOverride: nil)
        XCTAssertNil(urlParams.publicKey)
        XCTAssertEqual(urlParams.apiKeyOverride, "uk_1234")
        XCTAssertEqual(urlParams.merchantIdOverride, "acct_123")
        XCTAssertEqual(urlParams.platformIdOverride, "acct_123")
        XCTAssertEqual(urlParams.livemodeOverride, false)
    }
}
