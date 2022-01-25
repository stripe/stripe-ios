//
//  LinkedAccountFetcherTests.swift
//  StripeConnectionsTests
//
//  Created by Vardges Avetisyan on 12/30/21.
//

import XCTest
@testable import StripeConnections
@_spi(STP) import StripeCore
@_spi(STP) import StripeCoreTestUtils

class PaginatedAPIClient: ConnectionsAPIClient {

    // MARK: - Init

    init(count: Int, limit: Int) {
        self.count = count
        self.limit = limit
    }

    // MARK: - Properties

    private let count: Int
    private let limit: Int
    private lazy var accounts: [StripeAPI.LinkedAccount] = (0...count-1).map {
        StripeAPI.LinkedAccount(balance: nil,
                                balanceRefresh: nil,
                                displayName: "\($0)",
                                institutionName: "TestBank",
                                last4: "\($0)",
                                accountholder: nil,
                                category: .cash,
                                created: 1,
                                id: "\($0)",
                                livemode: false,
                                permissions: nil,
                                status: .active,
                                subcategory: .checking,
                                supportedPaymentMethodTypes: [.usBankAccount],
                                _allResponseFieldsStorage: nil)
    }

    // MARK: - ConnectionsAPIClient

    func generateLinkAccountSessionManifest(clientSecret: String) -> Promise<LinkAccountSessionManifest> {
        return Promise<LinkAccountSessionManifest>()
    }

    func fetchLinkedAccounts(clientSecret: String,
                             startingAfterAccountId: String?) -> Promise<StripeAPI.LinkedAccountList> {
        guard let startingAfterAccountId = startingAfterAccountId, let index = Int(startingAfterAccountId) else {
            let list = StripeAPI.LinkedAccountList(data: subarray(start: 0),
                                                   hasMore: true)
            return Promise<StripeAPI.LinkedAccountList>(value: list)

        }
        let subArray = subarray(start: index + 1)
        let hasMore = index + limit < accounts.count - 1
        let list = StripeAPI.LinkedAccountList(data: subArray,
                                               hasMore: hasMore)
        return Promise<StripeAPI.LinkedAccountList>(value: list)
    }

    func fetchLinkedAccountSession(clientSecret: String) -> Promise<StripeAPI.LinkAccountSession> {
        return Promise<StripeAPI.LinkAccountSession>()
    }

    // MARK: - Helpers

    fileprivate func subarray(start: Int) -> [StripeAPI.LinkedAccount] {
        guard start + limit < accounts.count else {
            return Array<StripeAPI.LinkedAccount>(accounts[start...])
        }
        return Array<StripeAPI.LinkedAccount>(accounts[start...start + limit])
    }
}

class LinkedAccountFetcherTests: XCTestCase {

    func testPaginationMax100() {
        let fetcher = LinkedAccountAPIFetcher(api: PaginatedAPIClient(count: 120, limit: 1), clientSecret: "")
        fetcher.fetchLinkedAccounts(initial: []).observe { result in
            switch result {
            case .success(let linkedAccounts):
                XCTAssertEqual(linkedAccounts.count, 100)
            case .failure(_):
                XCTFail()
            }
        }
    }

    func testPaginationUnderLimit() {
        let fetcher = LinkedAccountAPIFetcher(api: PaginatedAPIClient(count: 3, limit: 1), clientSecret: "")
        fetcher.fetchLinkedAccounts(initial: []).observe { result in
            switch result {
            case .success(let linkedAccounts):
                XCTAssertEqual(linkedAccounts.count, 3)
            case .failure(_):
                XCTFail()
            }
        }
    }

    func testPaginationUnderLimitLargePageSize() {
        let fetcher = LinkedAccountAPIFetcher(api: PaginatedAPIClient(count: 3, limit: 10), clientSecret: "")
        fetcher.fetchLinkedAccounts(initial: []).observe { result in
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
        let fetcher = LinkedAccountAPIFetcher(api: PaginatedAPIClient(count: 80, limit: 10), clientSecret: "")
        fetcher.fetchLinkedAccounts(initial: []).observe { result in
            switch result {
            case .success(let linkedAccounts):
                XCTAssertEqual(linkedAccounts.count, 80)
            case .failure(_):
                XCTFail()
            }
        }
    }
}
