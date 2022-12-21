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
    func fetchFinancialConnectionsAccounts(clientSecret: String, startingAfterAccountId: String?) -> Promise<StripeAPI.FinancialConnectionsSession.AccountList> {
        return Promise<StripeAPI.FinancialConnectionsSession.AccountList>()
    }

    func fetchFinancialConnectionsSession(clientSecret: String) -> Promise<StripeAPI.FinancialConnectionsSession> {
        return Promise<StripeAPI.FinancialConnectionsSession>()
    }

    func generateSessionManifest(clientSecret: String, returnURL: String?) -> Promise<FinancialConnectionsSynchronize> {
        return Promise<FinancialConnectionsSynchronize>()
    }
    
    func markConsentAcquired(clientSecret: String) -> Promise<FinancialConnectionsSessionManifest> {
        return Promise<FinancialConnectionsSessionManifest>()
    }

    func fetchFeaturedInstitutions(clientSecret: String) -> Promise<FinancialConnectionsInstitutionList> {
        return Promise<FinancialConnectionsInstitutionList>()
    }
    
    func fetchInstitutions(clientSecret: String, query: String) -> Promise<FinancialConnectionsInstitutionList> {
        return Promise<FinancialConnectionsInstitutionList>()
    }

    func createAuthSession(clientSecret: String, institutionId: String) -> Promise<FinancialConnectionsAuthSession> {
        return Promise<FinancialConnectionsAuthSession>()
    }
    
    func cancelAuthSession(clientSecret: String, authSessionId: String) -> Promise<FinancialConnectionsAuthSession> {
        return Promise<FinancialConnectionsAuthSession>()
    }
    
    func fetchAuthSessionOAuthResults(clientSecret: String, authSessionId: String) -> Future<FinancialConnectionsMixedOAuthParams> {
        return Promise<FinancialConnectionsMixedOAuthParams>()
    }
    
    func authorizeAuthSession(clientSecret: String, authSessionId: String, publicToken: String?) -> Promise<FinancialConnectionsAuthSession> {
        return Promise<FinancialConnectionsAuthSession>()
    }
    
    func fetchAuthSessionAccounts(
        clientSecret: String,
        authSessionId: String,
        initialPollDelay: TimeInterval
    ) -> Future<FinancialConnectionsAuthSessionAccounts> {
        return Promise<FinancialConnectionsAuthSessionAccounts>()
    }
    
    func selectAuthSessionAccounts(clientSecret: String, authSessionId: String, selectedAccountIds: [String]) -> Promise<FinancialConnectionsAuthSessionAccounts> {
        return Promise<FinancialConnectionsAuthSessionAccounts>()
    }
    
    func markLinkingMoreAccounts(clientSecret: String) -> Promise<FinancialConnectionsSessionManifest> {
        return Promise<FinancialConnectionsSessionManifest>()
    }
    
    func completeFinancialConnectionsSession(clientSecret: String) -> Future<StripeAPI.FinancialConnectionsSession> {
        return Promise<StripeAPI.FinancialConnectionsSession>()
    }
    
    func attachBankAccountToLinkAccountSession(
        clientSecret: String,
        accountNumber: String,
        routingNumber: String
    ) -> Future<FinancialConnectionsPaymentAccountResource> {
        return Promise<FinancialConnectionsPaymentAccountResource>()
    }
    
    func attachLinkedAccountIdToLinkAccountSession(
        clientSecret: String,
        linkedAccountId: String,
        consumerSessionClientSecret: String?
    ) -> Future<FinancialConnectionsPaymentAccountResource> {
        return Promise<FinancialConnectionsPaymentAccountResource>()
    }
    
    func recordAuthSessionEvent(
        clientSecret: String,
        authSessionId: String,
        eventNamespace: String,
        eventName: String
    ) -> Future<EmptyResponse> {
        return Promise<EmptyResponse>()
    }
}

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
        mockAnalyticsClient.reset()
    }

    func testAnalytics() {
        let sheet = FinancialConnectionsSheet(financialConnectionsSessionClientSecret: mockClientSecret, returnURL: nil, analyticsClient: mockAnalyticsClient)
        sheet.present(from: mockViewController) { _ in }

        // Verify presented analytic is logged
        XCTAssertEqual(mockAnalyticsClient.loggedAnalytics.count, 1)
        guard let presentedAnalytic = mockAnalyticsClient.loggedAnalytics.first as? FinancialConnectionsSheetPresentedAnalytic else {
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
        guard let closedAnalytic = mockAnalyticsClient.loggedAnalytics.last as? FinancialConnectionsSheetClosedAnalytic else {
            return XCTFail("Expected `FinancialConnectionsSheetClosedAnalytic`")
        }
        XCTAssertEqual(closedAnalytic.clientSecret, mockClientSecret)
        XCTAssertEqual(closedAnalytic.result, "cancelled")
    }

    func testAnalyticsProductUsage() {
        let _ = FinancialConnectionsSheet(financialConnectionsSessionClientSecret: mockClientSecret, returnURL: nil, analyticsClient: mockAnalyticsClient)
        XCTAssertEqual(mockAnalyticsClient.productUsage, ["FinancialConnectionsSheet"])
    }
}
