//
//  SessionFetcherTests.swift
//  StripeFinancialConnectionsTests
//
//  Created by Vardges Avetisyan on 1/20/22.
//

@_spi(STP) import StripeCore
@_spi(STP) import StripeCoreTestUtils
@testable import StripeFinancialConnections
import XCTest

class NoMoreAccountSessionAPIClient: EmptyFinancialConnectionsAPIClient {

    // MARK: - Properties

    private let hasMore: Bool

    // MARK: - Init

    init(hasMore: Bool) {
        self.hasMore = hasMore
    }

    // MARK: - FinancialConnectionsAPIClient

    override func fetchFinancialConnectionsAccounts(clientSecret: String, startingAfterAccountId: String?) -> Promise<
        StripeAPI.FinancialConnectionsSession.AccountList
    > {
        let account = StripeAPI.FinancialConnectionsAccount(
            balance: nil,
            balanceRefresh: nil,
            ownership: nil,
            ownershipRefresh: nil,
            displayName: nil,
            institutionName: "bank",
            last4: nil,
            category: .credit,
            created: 3,
            id: "12",
            livemode: false,
            permissions: nil,
            status: .active,
            subcategory: .checking,
            supportedPaymentMethodTypes: [.usBankAccount]
        )
        let fullList = StripeAPI.FinancialConnectionsSession.AccountList(data: [account], hasMore: false)
        return Promise(value: fullList)
    }

    override func fetchFinancialConnectionsSession(clientSecret: String) -> Promise<
        StripeAPI.FinancialConnectionsSession
    > {
        let fullList = StripeAPI.FinancialConnectionsSession.AccountList(data: [], hasMore: hasMore)
        let sessionWithFullAccountList = StripeAPI.FinancialConnectionsSession(
            clientSecret: "las",
            id: "1234",
            accounts: fullList,
            livemode: false,
            paymentAccount: nil,
            bankAccountToken: nil,
            status: nil,
            statusDetails: nil
        )
        return Promise(value: sessionWithFullAccountList)
    }
}

class SessionFetcherTests: XCTestCase {

    func testShouldNotFetchAccountsIfSessionIsExhaustive() {
        let api = NoMoreAccountSessionAPIClient(hasMore: false)
        let accountFetcher = FinancialConnectionsAccountAPIFetcher(api: api, clientSecret: "las")
        let fetcher = FinancialConnectionsSessionAPIFetcher(
            api: api,
            clientSecret: "las",
            accountFetcher: accountFetcher
        )

        fetcher.fetchSession().observe(on: nil) { (result) in
            switch result {
            case .success(let session):
                XCTAssertEqual(session.accounts.data.count, 0)
            case .failure:
                XCTFail()
            }
        }
    }

    func testShouldFetchMoreAccountsIfSessionHasMore() {
        let api = NoMoreAccountSessionAPIClient(hasMore: true)
        let accountFetcher = FinancialConnectionsAccountAPIFetcher(api: api, clientSecret: "las")
        let fetcher = FinancialConnectionsSessionAPIFetcher(
            api: api,
            clientSecret: "las",
            accountFetcher: accountFetcher
        )

        fetcher.fetchSession().observe(on: nil) { (result) in
            switch result {
            case .success(let session):
                XCTAssertEqual(session.accounts.data.count, 1)
            case .failure:
                XCTFail()
            }
        }
    }
}
