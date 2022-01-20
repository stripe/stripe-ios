//
//  LinkedAccountFetcher.swift
//  StripeConnections
//
//  Created by Vardges Avetisyan on 12/30/21.
//

import Foundation
@_spi(STP) import StripeCore

protocol LinkedAccountFetcher {
    func fetchLinkedAccounts(
        initial: [StripeAPI.LinkedAccount]
    ) -> Future<[StripeAPI.LinkedAccount]>
}

class LinkedAccountAPIFetcher: LinkedAccountFetcher {

    // MARK: - Properties

    fileprivate let api: ConnectionsAPIClient
    fileprivate let clientSecret: String

    // MARK: - Init

    init(api: ConnectionsAPIClient, clientSecret: String) {
        self.api = api
        self.clientSecret = clientSecret
    }

    // MARK: - LinkedAccountFetcher

    func fetchLinkedAccounts(initial: [StripeAPI.LinkedAccount]) -> Future<[StripeAPI.LinkedAccount]> {
        return fetchLinkedAccounts(resultsSoFar: initial)
    }
}

// MARK: - Helpers

extension LinkedAccountAPIFetcher {

    fileprivate func fetchLinkedAccounts(
        resultsSoFar: [StripeAPI.LinkedAccount]
    ) -> Future<[StripeAPI.LinkedAccount]> {
        let lastId = resultsSoFar.last?.id
        let promise = api.fetchLinkedAccounts(clientSecret: clientSecret,
                                              startingAfterAccountId: lastId)
        return promise.chained { list in
            let combinedResults = resultsSoFar + list.data
            guard list.hasMore, combinedResults.count < Constants.maxAccountLimit else {
                return Promise(value: combinedResults)
            }
            return self.fetchLinkedAccounts(resultsSoFar: combinedResults)
        }

    }
}

// MARK: - Constants

extension LinkedAccountAPIFetcher {
    fileprivate enum Constants {
        static let maxAccountLimit = 100
    }
}
