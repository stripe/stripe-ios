//
//  LinkAccountSessionFetcherTests.swift
//  StripeConnectionsTests
//
//  Created by Vardges Avetisyan on 1/20/22.
//

import XCTest
@testable import StripeConnections
@_spi(STP) import StripeCore
@_spi(STP) import StripeCoreTestUtils

class NoMoreAccountSessionAPIClient: ConnectionsAPIClient {

    // MARK: - Properties

    fileprivate let hasMore: Bool

    // MARK: - Init

    init(hasMore: Bool) {
        self.hasMore = hasMore
    }

    // MARK: - ConnectionsAPIClient

    func generateLinkAccountSessionManifest(clientSecret: String) -> Promise<LinkAccountSessionManifest> {
        return Promise<LinkAccountSessionManifest>()
    }

    func fetchLinkedAccounts(clientSecret: String, startingAfterAccountId: String?) -> Promise<StripeAPI.LinkedAccountList> {
        let account = StripeAPI.LinkedAccount(balance: nil, balanceRefresh: nil, displayName: nil, institutionName: "bank", last4: nil, accountholder: nil, category: .credit, created: 3, id: "12", livemode: false, permissions: nil, status: .active, subcategory: .checking, supportedPaymentMethodTypes: [.usBankAccount], _allResponseFieldsStorage: nil)
        let fullList = StripeAPI.LinkedAccountList(data: [account], hasMore: false)
        return Promise(value: fullList)
    }

    func fetchLinkedAccountSession(clientSecret: String) -> Promise<StripeAPI.LinkAccountSession> {
        let fullList = StripeAPI.LinkedAccountList(data: [], hasMore: hasMore)
        let sessionWithFullAccountList = StripeAPI.LinkAccountSession(clientSecret: "las",
                                                                      id: "1234",
                                                                      linkedAccounts: fullList,
                                                                      livemode: false,
                                                                      paymentAccount: nil)
        return Promise(value: sessionWithFullAccountList)
    }
}

class LinkAccountSessionFetcherTests: XCTestCase {

    func testShouldNotFetchAccountsIfSessionIsExhaustive() {
        let api = NoMoreAccountSessionAPIClient(hasMore: false)
        let accountFetcher = LinkedAccountAPIFetcher(api: api, clientSecret: "las")
        let fetcher = LinkAccountSessionAPIFetcher(api: api, clientSecret: "las", accountFetcher: accountFetcher)

        fetcher.fetchSession().observe(on: nil) { (result) in
            switch result {
            case .success(let session):
                XCTAssertEqual(session.linkedAccounts.data.count, 0)
            case .failure(_):
                XCTFail()
            }
        }
    }

    func testShouldFetchMoreAccountsIfSessionHasMore() {
        let api = NoMoreAccountSessionAPIClient(hasMore: true)
        let accountFetcher = LinkedAccountAPIFetcher(api: api, clientSecret: "las")
        let fetcher = LinkAccountSessionAPIFetcher(api: api, clientSecret: "las", accountFetcher: accountFetcher)

        fetcher.fetchSession().observe(on: nil) { (result) in
            switch result {
            case .success(let session):
                XCTAssertEqual(session.linkedAccounts.data.count, 1)
            case .failure(_):
                XCTFail()
            }
        }
    }
}
