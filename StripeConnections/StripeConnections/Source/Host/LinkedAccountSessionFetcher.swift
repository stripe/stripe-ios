//
//  LinkAccountSessionFetcher.swift
//  StripeConnections
//
//  Created by Vardges Avetisyan on 1/20/22.
//

import Foundation
@_spi(STP) import StripeCore

protocol LinkAccountSessionFetcher {
    func fetchSession() -> Future<StripeAPI.LinkAccountSession>
}

class LinkAccountSessionAPIFetcher: LinkAccountSessionFetcher {

    // MARK: - Properties

    fileprivate let api: ConnectionsAPIClient
    fileprivate let clientSecret: String
    fileprivate let accountFetcher: LinkedAccountFetcher

    // MARK: - Init

    init(api: ConnectionsAPIClient,
         clientSecret: String,
         accountFetcher: LinkedAccountFetcher) {
        self.api = api
        self.clientSecret = clientSecret
        self.accountFetcher = accountFetcher
    }

    // MARK: - LinkedAccountFetcher

    func fetchSession() -> Future<StripeAPI.LinkAccountSession> {
        api.fetchLinkedAccountSession(clientSecret: clientSecret).chained { [weak self] session in
            guard session.linkedAccounts.hasMore, let self = self else {
                return Promise(value: session)
            }

            return self.accountFetcher
                .fetchLinkedAccounts(initial: session.linkedAccounts.data)
                .chained { fullAccountList in
                    /**
                     Here we create a synthetic LinkAccountSession object with full account list.
                     */
                    let fullList = StripeAPI.LinkedAccountList(data: fullAccountList, hasMore: false)
                    let sessionWithFullAccountList = StripeAPI.LinkAccountSession(clientSecret: session.clientSecret,
                                                                                  id: session.id,
                                                                                  linkedAccounts: fullList,
                                                                                  livemode: session.livemode,
                                                                                  paymentAccount: session.paymentAccount)
                    return Promise(value: sessionWithFullAccountList)
            }
        }
    }

}
