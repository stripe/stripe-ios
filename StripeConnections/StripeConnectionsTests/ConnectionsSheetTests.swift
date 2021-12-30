//
//  ConnectionsSheetTests.swift
//  StripeConnectionsTests
//
//  Created by Vardges Avetisyan on 11/9/21.
//

import XCTest
@testable import StripeConnections
@_spi(STP) import StripeCore
@_spi(STP) import StripeCoreTestUtils

class EmptyConnectionsAPIClient: ConnectionsAPIClient {
    func generateLinkAccountSessionManifest(clientSecret: String) -> Promise<LinkAccountSessionManifest> {
        return Promise<LinkAccountSessionManifest>()
    }

    func fetchLinkedAccounts(clientSecret: String, startingAfterAccountId: String?) -> Promise<LinkedAccountList> {
        return Promise<LinkedAccountList>()
    }
}

class EmptyAccountFetcher: LinkedAccountFetcher {
    func fetchLinkedAccounts() -> Future<[StripeAPI.LinkedAccount]> {
        return Promise<[StripeAPI.LinkedAccount]>()
    }
}

@available(iOS 12, *)
class ConnectionsSheetTests: XCTestCase {
    private let mockViewController = UIViewController()
    private let mockClientSecret = "las_123345"
    private let mockAnalyticsClient = MockAnalyticsClient()

    override func setUpWithError() throws {
        mockAnalyticsClient.reset()
    }

    func testAnalytics() {
        let sheet = ConnectionsSheet(linkAccountSessionClientSecret: mockClientSecret, analyticsClient: mockAnalyticsClient)
        sheet.present(from: mockViewController) { _ in }

        // Verify presented analytic is logged
        XCTAssertEqual(mockAnalyticsClient.loggedAnalytics.count, 1)
        guard let presentedAnalytic = mockAnalyticsClient.loggedAnalytics.first as? ConnectionsSheetPresentedAnalytic else {
            return XCTFail("Expected `ConnectionsSheetPresentedAnalytic`")
        }
        XCTAssertEqual(presentedAnalytic.clientSecret, mockClientSecret)

        // Mock that connections is completed
        let mockVC = ConnectionsHostViewController(linkAccountSessionClientSecret: mockClientSecret, apiClient: EmptyConnectionsAPIClient(), accountFetcher: EmptyAccountFetcher())
        sheet.connectionsHostViewController(mockVC, didFinish: .canceled)

        // Verify closed analytic is logged
        XCTAssertEqual(mockAnalyticsClient.loggedAnalytics.count, 2)
        guard let closedAnalytic = mockAnalyticsClient.loggedAnalytics.last as? ConnectionsSheetClosedAnalytic else {
            return XCTFail("Expected `ConnectionsSheetClosedAnalytic`")
        }
        XCTAssertEqual(closedAnalytic.clientSecret, mockClientSecret)
        XCTAssertEqual(closedAnalytic.result, "cancelled")
    }

    func testAnalyticsProductUsage() {
        let _ = ConnectionsSheet(linkAccountSessionClientSecret: mockClientSecret, analyticsClient: mockAnalyticsClient)
        XCTAssertEqual(mockAnalyticsClient.productUsage, ["ConnectionsSheet"])
    }
}
