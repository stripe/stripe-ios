//
//  FinancialConnectionsSheetTests.swift
//  StripeFinancialConnectionsTests
//
//  Created by Vardges Avetisyan on 11/9/21.
//

import XCTest
@testable import StripeFinancialConnections
@_spi(STP) import StripeCore
@_spi(STP) import StripeCoreTestUtils

class EmptyFinancialConnectionsAPIClient: FinancialConnectionsAPIClient {
    func fetchLinkedAccounts(clientSecret: String, startingAfterAccountId: String?) -> Promise<StripeAPI.LinkedAccountList> {
        return Promise<StripeAPI.LinkedAccountList>()
    }

    func fetchLinkedAccountSession(clientSecret: String) -> Promise<StripeAPI.LinkAccountSession> {
        return Promise<StripeAPI.LinkAccountSession>()
    }

    func generateLinkAccountSessionManifest(clientSecret: String) -> Promise<LinkAccountSessionManifest> {
        return Promise<LinkAccountSessionManifest>()
    }
}

class EmptyLinkAccountSessionFetcher: LinkAccountSessionFetcher {
    func fetchSession() -> Future<StripeAPI.LinkAccountSession> {
        return Promise<StripeAPI.LinkAccountSession>()
    }
}

class FinancialConnectionsSheetTests: XCTestCase {
    private let mockViewController = UIViewController()
    private let mockClientSecret = "las_123345"
    private let mockAnalyticsClient = MockAnalyticsClient()

    override func setUpWithError() throws {
        mockAnalyticsClient.reset()
    }

    func testAnalytics() {
        let sheet = FinancialConnectionsSheet(linkAccountSessionClientSecret: mockClientSecret, analyticsClient: mockAnalyticsClient)
        sheet.present(from: mockViewController) { _ in }

        // Verify presented analytic is logged
        XCTAssertEqual(mockAnalyticsClient.loggedAnalytics.count, 1)
        guard let presentedAnalytic = mockAnalyticsClient.loggedAnalytics.first as? FinancialConnectionsSheetPresentedAnalytic else {
            return XCTFail("Expected `FinancialConnectionsSheetPresentedAnalytic`")
        }
        XCTAssertEqual(presentedAnalytic.clientSecret, mockClientSecret)

        // Mock that financialConnections is completed
        let mockVC = FinancialConnectionsHostViewController(linkAccountSessionClientSecret: mockClientSecret, apiClient: EmptyFinancialConnectionsAPIClient(), linkAccountSessionFetcher: EmptyLinkAccountSessionFetcher())
        sheet.financialConnectionsHostViewController(mockVC, didFinish: .canceled)

        // Verify closed analytic is logged
        XCTAssertEqual(mockAnalyticsClient.loggedAnalytics.count, 2)
        guard let closedAnalytic = mockAnalyticsClient.loggedAnalytics.last as? FinancialConnectionsSheetClosedAnalytic else {
            return XCTFail("Expected `FinancialConnectionsSheetClosedAnalytic`")
        }
        XCTAssertEqual(closedAnalytic.clientSecret, mockClientSecret)
        XCTAssertEqual(closedAnalytic.result, "cancelled")
    }

    func testAnalyticsProductUsage() {
        let _ = FinancialConnectionsSheet(linkAccountSessionClientSecret: mockClientSecret, analyticsClient: mockAnalyticsClient)
        XCTAssertEqual(mockAnalyticsClient.productUsage, ["FinancialConnectionsSheet"])
    }
}
