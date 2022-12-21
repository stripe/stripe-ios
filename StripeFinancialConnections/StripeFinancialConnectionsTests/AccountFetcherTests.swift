//
//  AccountFetcherTests.swift
//  StripeFinancialConnectionsTests
//
//  Created by Vardges Avetisyan on 12/30/21.
//

import XCTest
@testable import StripeFinancialConnections
@_spi(STP) import StripeCore
@_spi(STP) import StripeCoreTestUtils

class PaginatedAPIClient: FinancialConnectionsAPIClient {

    // MARK: - Init

    init(count: Int, limit: Int) {
        self.count = count
        self.limit = limit
    }

    // MARK: - Properties

    private let count: Int
    private let limit: Int
    private lazy var accounts: [StripeAPI.FinancialConnectionsAccount] = (0...count-1).map {
        StripeAPI.FinancialConnectionsAccount(balance: nil,
                                              balanceRefresh: nil,
                                              ownership: nil,
                                              ownershipRefresh: nil,
                                              displayName: "\($0)",
                                              institutionName: "TestBank",
                                              last4: "\($0)",
                                              category: .cash,
                                              created: 1,
                                              id: "\($0)",
                                              livemode: false,
                                              permissions: nil,
                                              status: .active,
                                              subcategory: .checking,
                                              supportedPaymentMethodTypes: [.usBankAccount])
    }

    // MARK: - FinancialConnectionsAPIClient

    func generateSessionManifest(clientSecret: String, returnURL: String?) -> Promise<FinancialConnectionsSynchronize> {
        return Promise<FinancialConnectionsSynchronize>()
    }

    func fetchFinancialConnectionsAccounts(clientSecret: String,
                             startingAfterAccountId: String?) -> Promise<StripeAPI.FinancialConnectionsSession.AccountList> {
        guard let startingAfterAccountId = startingAfterAccountId, let index = Int(startingAfterAccountId) else {
            let list = StripeAPI.FinancialConnectionsSession.AccountList(data: subarray(start: 0),
                                                   hasMore: true)
            return Promise<StripeAPI.FinancialConnectionsSession.AccountList>(value: list)

        }
        let subArray = subarray(start: index + 1)
        let hasMore = index + limit < accounts.count - 1
        let list = StripeAPI.FinancialConnectionsSession.AccountList(data: subArray,
                                               hasMore: hasMore)
        return Promise<StripeAPI.FinancialConnectionsSession.AccountList>(value: list)
    }

    func fetchFinancialConnectionsSession(clientSecret: String) -> Promise<StripeAPI.FinancialConnectionsSession> {
        return Promise<StripeAPI.FinancialConnectionsSession>()
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
    
    // MARK: - Helpers

    private func subarray(start: Int) -> [StripeAPI.FinancialConnectionsAccount] {
        guard start + limit < accounts.count else {
            return Array<StripeAPI.FinancialConnectionsAccount>(accounts[start...])
        }
        return Array<StripeAPI.FinancialConnectionsAccount>(accounts[start...start + limit])
    }
}

class AccountFetcherTests: XCTestCase {

    func testPaginationMax100() {
        let fetcher = FinancialConnectionsAccountAPIFetcher(api: PaginatedAPIClient(count: 120, limit: 1), clientSecret: "")
        fetcher.fetchAccounts(initial: []).observe { result in
            switch result {
            case .success(let linkedAccounts):
                XCTAssertEqual(linkedAccounts.count, 100)
            case .failure(_):
                XCTFail()
            }
        }
    }

    func testPaginationUnderLimit() {
        let fetcher = FinancialConnectionsAccountAPIFetcher(api: PaginatedAPIClient(count: 3, limit: 1), clientSecret: "")
        fetcher.fetchAccounts(initial: []).observe { result in
            switch result {
            case .success(let linkedAccounts):
                XCTAssertEqual(linkedAccounts.count, 3)
            case .failure(_):
                XCTFail()
            }
        }
    }

    func testPaginationUnderLimitLargePageSize() {
        let fetcher = FinancialConnectionsAccountAPIFetcher(api: PaginatedAPIClient(count: 3, limit: 10), clientSecret: "")
        fetcher.fetchAccounts(initial: []).observe { result in
            switch result {
            case .success(let linkedAccounts):
                let info = linkedAccounts.map { $0.id }
                print(info)
                XCTAssertEqual(linkedAccounts.count, 3)
            case .failure(_):
                XCTFail()
            }
        }
    }

    func testPaginationUnderLimitSmallPageSize() {
        let fetcher = FinancialConnectionsAccountAPIFetcher(api: PaginatedAPIClient(count: 80, limit: 10), clientSecret: "")
        fetcher.fetchAccounts(initial: []).observe { result in
            switch result {
            case .success(let linkedAccounts):
                XCTAssertEqual(linkedAccounts.count, 80)
            case .failure(_):
                XCTFail()
            }
        }
    }
}
