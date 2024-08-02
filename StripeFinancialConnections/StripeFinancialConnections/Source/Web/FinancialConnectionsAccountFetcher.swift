//
//  FinancialConnectionsAccountFetcher.swift
//  StripeFinancialConnections
//
//  Created by Vardges Avetisyan on 12/30/21.
//

import Foundation
@_spi(STP) import StripeCore

protocol FinancialConnectionsAccountFetcher {
    func fetchAccounts(
        initial: [StripeAPI.FinancialConnectionsAccount]
    ) -> Future<[StripeAPI.FinancialConnectionsAccount]>
}

class FinancialConnectionsAccountAPIFetcher: FinancialConnectionsAccountFetcher {

    // MARK: - Properties

    private let api: FinancialConnectionsAPI
    private let clientSecret: String

    // MARK: - Init

    init(api: FinancialConnectionsAPI, clientSecret: String) {
        self.api = api
        self.clientSecret = clientSecret
    }

    // MARK: - FinancialConnectionsAccountFetcher

    func fetchAccounts(initial: [StripeAPI.FinancialConnectionsAccount]) -> Future<
        [StripeAPI.FinancialConnectionsAccount]
    > {
        return fetchAccounts(resultsSoFar: initial)
    }
}

// MARK: - Helpers

extension FinancialConnectionsAccountAPIFetcher {

    private func fetchAccounts(
        resultsSoFar: [StripeAPI.FinancialConnectionsAccount]
    ) -> Future<[StripeAPI.FinancialConnectionsAccount]> {
        let lastId = resultsSoFar.last?.id
        let promise = api.fetchFinancialConnectionsAccounts(
            clientSecret: clientSecret,
            startingAfterAccountId: lastId
        )
        return promise.chained { list in
            let combinedResults = resultsSoFar + list.data
            guard list.hasMore, combinedResults.count < Constants.maxAccountLimit else {
                return Promise(value: combinedResults)
            }
            return self.fetchAccounts(resultsSoFar: combinedResults)
        }

    }
}

// MARK: - Constants

extension FinancialConnectionsAccountAPIFetcher {
    private enum Constants {
        static let maxAccountLimit = 100
    }
}
