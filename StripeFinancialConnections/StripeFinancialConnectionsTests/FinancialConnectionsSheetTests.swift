//
//  FinancialConnectionsSheetTests.swift
//  StripeFinancialConnectionsTests
//
//  Created by Vardges Avetisyan on 11/9/21.
//

@_spi(STP) import StripeCore
@_spi(STP) import StripeCoreTestUtils
@testable import StripeFinancialConnections
import XCTest

class EmptySessionFetcher: FinancialConnectionsSessionFetcher {
    func fetchSession() -> Future<StripeAPI.FinancialConnectionsSession> {
        return Promise<StripeAPI.FinancialConnectionsSession>()
    }
}

class FinancialConnectionsSheetTests: XCTestCase {
    private let mockViewController = UIViewController()
    private let mockClientSecret = "las_123345"
    private let mockAnalyticsClient = MockAnalyticsClient()

    override func setUpWithError() throws {
        try super.setUpWithError()
        mockAnalyticsClient.reset()
    }

    func testAnalytics() {
        let sheet = FinancialConnectionsSheet(
            financialConnectionsSessionClientSecret: mockClientSecret,
            returnURL: nil,
            analyticsClient: mockAnalyticsClient
        )
        sheet.present(from: mockViewController) { _ in }

        // Verify presented analytic is logged
        XCTAssertEqual(mockAnalyticsClient.loggedAnalytics.count, 1)
        guard
            let presentedAnalytic = mockAnalyticsClient.loggedAnalytics.first
                as? FinancialConnectionsSheetPresentedAnalytic
        else {
            return XCTFail("Expected `FinancialConnectionsSheetPresentedAnalytic`")
        }
        XCTAssertEqual(presentedAnalytic.clientSecret, mockClientSecret)

        // Mock that financialConnections is completed
        let host = HostController(
            api: EmptyFinancialConnectionsAPIClient(),
            clientSecret: "test",
            returnURL: nil,
            publishableKey: "test",
            stripeAccount: nil
        )
        sheet.hostController(host, viewController: UIViewController(), didFinish: .canceled)

        // Verify closed analytic is logged
        XCTAssertEqual(mockAnalyticsClient.loggedAnalytics.count, 2)
        guard let closedAnalytic = mockAnalyticsClient.loggedAnalytics.last as? FinancialConnectionsSheetClosedAnalytic
        else {
            return XCTFail("Expected `FinancialConnectionsSheetClosedAnalytic`")
        }
        XCTAssertEqual(closedAnalytic.clientSecret, mockClientSecret)
        XCTAssertEqual(closedAnalytic.result, "cancelled")
    }

    func testAnalyticsProductUsage() {
        _ = FinancialConnectionsSheet(
            financialConnectionsSessionClientSecret: mockClientSecret,
            returnURL: nil,
            analyticsClient: mockAnalyticsClient
        )
        XCTAssertEqual(mockAnalyticsClient.productUsage, ["FinancialConnectionsSheet"])
    }
}
