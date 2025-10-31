//
//  FinancialConnectionsSheetTests.swift
//  StripeFinancialConnectionsTests
//
//  Created by Vardges Avetisyan on 11/9/21.
//

@_spi(STP) import StripeCore
@_spi(STP) import StripeCoreTestUtils
@testable @_spi(STP) import StripeFinancialConnections
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
    private let mockApiClient = FinancialConnectionsAsyncAPIClient(
        apiClient: APIStubbedTestCase.stubbedAPIClient()
    )

    override func setUpWithError() throws {
        try super.setUpWithError()
        mockAnalyticsClient.reset()
    }

    func testPresentCompletion() {
        let sheet = FinancialConnectionsSheet(
            financialConnectionsSessionClientSecret: mockClientSecret,
            returnURL: nil,
            configuration: .init(),
            analyticsClient: mockAnalyticsClient
        )

        let expectation = expectation(description: "presentation completed")
        sheet.present(from: mockViewController) { (result: FinancialConnectionsSheet.Result) in
            guard case .canceled = result else {
                XCTFail("Unexpected result: \(result)")
                return
            }
            expectation.fulfill()
        }

        // Mock that financialConnections is completed
        let host = HostController(
            apiClient: mockApiClient,
            analyticsClientV1: mockAnalyticsClient,
            clientSecret: "test",
            returnURL: nil,
            configuration: .init(),
            elementsSessionContext: nil,
            publishableKey: "test",
            stripeAccount: nil
        )
        sheet.hostController(
            host,
            viewController: mockViewController,
            didFinish: .canceled,
            linkAccountSessionId: "fcsess_123"
        )

        wait(for: [expectation], timeout: 5.0)
    }

    @MainActor
    func testAsyncPresentCompletion() async {
        let expectation = XCTestExpectation(description: "Sheet completion")

        let sheet = FinancialConnectionsSheet(
            financialConnectionsSessionClientSecret: mockClientSecret,
            returnURL: nil,
            configuration: .init(),
            analyticsClient: mockAnalyticsClient
        )

        Task {
            let result = await sheet.present(from: mockViewController)

            guard case .canceled = result else {
                XCTFail("Unexpected result: \(result)")
                return
            }

            expectation.fulfill()
        }

        // Mock that financialConnections is completed
        let host = HostController(
            apiClient: mockApiClient,
            analyticsClientV1: mockAnalyticsClient,
            clientSecret: "test",
            returnURL: nil,
            configuration: .init(),
            elementsSessionContext: nil,
            publishableKey: "test",
            stripeAccount: nil
        )

        // Ensure this is called on the main thread
        await MainActor.run {
            sheet.hostController(
                host,
                viewController: mockViewController,
                didFinish: .canceled,
                linkAccountSessionId: "fcsess_123"
            )
        }

        await fulfillment(of: [expectation], timeout: 1.0)
    }

    func testAnalytics() {
        let sheet = FinancialConnectionsSheet(
            financialConnectionsSessionClientSecret: mockClientSecret,
            returnURL: nil,
            configuration: .init(),
            analyticsClient: mockAnalyticsClient
        )
        sheet.present(from: mockViewController) { (_: FinancialConnectionsSheet.Result) in }

        // Verify presented analytic is logged
        XCTAssertEqual(mockAnalyticsClient.loggedAnalytics.count, 1)
        guard
            let presentedAnalytic = mockAnalyticsClient.loggedAnalytics.first
                as? FinancialConnectionsSheetPresentedAnalytic
        else {
            return XCTFail("Expected `FinancialConnectionsSheetPresentedAnalytic`")
        }
        // We don't have a `linkAccountSessionId` at this point.
        XCTAssertNil(presentedAnalytic.linkAccountSessionId)

        // Mock that financialConnections is completed
        let host = HostController(
            apiClient: mockApiClient,
            analyticsClientV1: mockAnalyticsClient,
            clientSecret: "test",
            returnURL: nil,
            configuration: .init(),
            elementsSessionContext: nil,
            publishableKey: "test",
            stripeAccount: nil
        )
        sheet.hostController(
            host,
            viewController: UIViewController(),
            didFinish: .canceled,
            linkAccountSessionId: "fcsess_123"
        )

        // Verify closed analytic is logged
        XCTAssertEqual(mockAnalyticsClient.loggedAnalytics.count, 2)
        guard let closedAnalytic = mockAnalyticsClient.loggedAnalytics.last as? FinancialConnectionsSheetClosedAnalytic
        else {
            return XCTFail("Expected `FinancialConnectionsSheetClosedAnalytic`")
        }

        XCTAssertEqual(closedAnalytic.linkAccountSessionId, "fcsess_123")
        XCTAssertEqual(closedAnalytic.result, "cancelled")
    }

    func testAnalyticsProductUsage() {
        _ = FinancialConnectionsSheet(
            financialConnectionsSessionClientSecret: mockClientSecret,
            returnURL: nil,
            configuration: .init(),
            analyticsClient: mockAnalyticsClient
        )
        XCTAssertEqual(mockAnalyticsClient.productUsage, ["FinancialConnectionsSheet"])
    }
}
