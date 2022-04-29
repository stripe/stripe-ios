//
//  FinancialConnectionsSessionFetcher.swift
//  StripeFinancialConnections
//
//  Created by Vardges Avetisyan on 1/20/22.
//

import Foundation
@_spi(STP) import StripeCore

protocol FinancialConnectionsSessionFetcher {
    func fetchSession() -> Future<StripeAPI.FinancialConnectionsSession>
}

class FinancialConnectionsSessionAPIFetcher: FinancialConnectionsSessionFetcher {

    // MARK: - Properties

    fileprivate let api: FinancialConnectionsAPIClient
    fileprivate let clientSecret: String
    fileprivate let accountFetcher: FinancialConnectionsAccountFetcher

    // MARK: - Init

    init(api: FinancialConnectionsAPIClient,
         clientSecret: String,
         accountFetcher: FinancialConnectionsAccountFetcher) {
        self.api = api
        self.clientSecret = clientSecret
        self.accountFetcher = accountFetcher
    }

    // MARK: - AccountFetcher

    func fetchSession() -> Future<StripeAPI.FinancialConnectionsSession> {
        api.fetchFinancialConnectionsSession(clientSecret: clientSecret).chained { [weak self] session in
            guard session.linkedAccounts.hasMore, let self = self else {
                return Promise(value: session)
            }

            return self.accountFetcher
                .fetchAccounts(initial: session.linkedAccounts.data)
                .chained { fullAccountList in
                    /**
                     Here we create a synthetic FinancialConnectionsSession object with full account list.
                     */
                    let fullList = StripeAPI.FinancialConnectionsSession.AccountList(data: fullAccountList, hasMore: false)
                    let sessionWithFullAccountList = StripeAPI.FinancialConnectionsSession(clientSecret: session.clientSecret,
                                                                                  id: session.id,
                                                                                  linkedAccounts: fullList,
                                                                                  livemode: session.livemode,
                                                                                  paymentAccount: session.paymentAccount,
                                                                                  bankAccountToken: session.bankAccountToken)
                    return Promise(value: sessionWithFullAccountList)
            }
        }
    }

}
