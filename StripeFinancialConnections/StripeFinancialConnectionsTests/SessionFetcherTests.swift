//
//  SessionFetcherTests.swift
//  StripeFinancialConnectionsTests
//
//  Created by Vardges Avetisyan on 1/20/22.
//

import XCTest
@testable import StripeFinancialConnections
@_spi(STP) import StripeCore
@_spi(STP) import StripeCoreTestUtils

class NoMoreAccountSessionAPIClient: FinancialConnectionsAPIClient {

    // MARK: - Properties

    private let hasMore: Bool

    // MARK: - Init

    init(hasMore: Bool) {
        self.hasMore = hasMore
    }

    // MARK: - FinancialConnectionsAPIClient

    func generateSessionManifest(clientSecret: String, returnURL: String?) -> Promise<FinancialConnectionsSynchronize> {
        return Promise<FinancialConnectionsSynchronize>()
    }

    func fetchFinancialConnectionsAccounts(clientSecret: String, startingAfterAccountId: String?) -> Promise<StripeAPI.FinancialConnectionsSession.AccountList> {
        let account = StripeAPI.FinancialConnectionsAccount(balance: nil, balanceRefresh: nil, ownership: nil, ownershipRefresh: nil, displayName: nil, institutionName: "bank", last4: nil, category: .credit, created: 3, id: "12", livemode: false, permissions: nil, status: .active, subcategory: .checking, supportedPaymentMethodTypes: [.usBankAccount])
        let fullList = StripeAPI.FinancialConnectionsSession.AccountList(data: [account], hasMore: false)
        return Promise(value: fullList)
    }

    func fetchFinancialConnectionsSession(clientSecret: String) -> Promise<StripeAPI.FinancialConnectionsSession> {
        let fullList = StripeAPI.FinancialConnectionsSession.AccountList(data: [], hasMore: hasMore)
        let sessionWithFullAccountList = StripeAPI.FinancialConnectionsSession(clientSecret: "las",
                                                                      id: "1234",
                                                                      accounts: fullList,
                                                                      livemode: false,
                                                                      paymentAccount: nil,
                                                                      bankAccountToken: nil)
        return Promise(value: sessionWithFullAccountList)
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

class SessionFetcherTests: XCTestCase {

    func testShouldNotFetchAccountsIfSessionIsExhaustive() {
        let api = NoMoreAccountSessionAPIClient(hasMore: false)
        let accountFetcher = FinancialConnectionsAccountAPIFetcher(api: api, clientSecret: "las")
        let fetcher = FinancialConnectionsSessionAPIFetcher(api: api, clientSecret: "las", accountFetcher: accountFetcher)

        fetcher.fetchSession().observe(on: nil) { (result) in
            switch result {
            case .success(let session):
                XCTAssertEqual(session.accounts.data.count, 0)
            case .failure(_):
                XCTFail()
            }
        }
    }

    func testShouldFetchMoreAccountsIfSessionHasMore() {
        let api = NoMoreAccountSessionAPIClient(hasMore: true)
        let accountFetcher = FinancialConnectionsAccountAPIFetcher(api: api, clientSecret: "las")
        let fetcher = FinancialConnectionsSessionAPIFetcher(api: api, clientSecret: "las", accountFetcher: accountFetcher)

        fetcher.fetchSession().observe(on: nil) { (result) in
            switch result {
            case .success(let session):
                XCTAssertEqual(session.accounts.data.count, 1)
            case .failure(_):
                XCTFail()
            }
        }
    }
}
