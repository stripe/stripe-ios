//
//  FCLiteAPIClient.swift
//  StripePaymentSheet
//
//  Created by Mat Schmid on 2025-03-12.
//

import Foundation
@_spi(STP) import StripeCore

struct FCLiteAPIClient {
    private enum Endpoint {
        case synchronize
        case sessionReceipt
        case listAccounts

        var path: String {
            switch self {
            case .synchronize: "financial_connections/sessions/synchronize"
            case .sessionReceipt: "link_account_sessions/session_receipt"
            case .listAccounts: "link_account_sessions/list_accounts"
            }
        }
    }

    private let backingAPIClient: STPAPIClient

    init(backingAPIClient: STPAPIClient) {
        self.backingAPIClient = backingAPIClient
    }

    private func get<T: Decodable>(
        endpoint: Endpoint,
        parameters: [String: Any]
    ) async throws -> T {
        try await withCheckedThrowingContinuation { continuation in
            backingAPIClient.get(
                resource: endpoint.path,
                parameters: parameters,
                completion: { (result: Result<T, Error>) in
                    switch result {
                    case .success(let response):
                        continuation.resume(returning: response)
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }
            )
        }
    }

    private func post<T: Decodable>(
        endpoint: Endpoint,
        parameters: [String: Any]
    ) async throws -> T {
        try await withCheckedThrowingContinuation { continuation in
            backingAPIClient.post(
                resource: endpoint.path,
                parameters: parameters,
                completion: { (result: Result<T, Error>) in
                    switch result {
                    case .success(let response):
                        continuation.resume(returning: response)
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }
            )
        }
    }
}

extension FCLiteAPIClient {
    func synchronize(
        clientSecret: String,
        returnUrl: URL
    ) async throws -> SynchronizePayload {
        let mobileParameters: [String: Any] = [
            "fullscreen": true,
            "app_return_url": returnUrl,
            // Uncomment when the `mobile_sdk_type` param is accepted:
            // "mobile_sdk_type": "FC_LITE",
        ]
        let parameters: [String: Any] = [
            "client_secret": clientSecret,
            "mobile": mobileParameters,
        ]
        return try await post(endpoint: .synchronize, parameters: parameters)
    }

    func fetchSession(
        clientSecret: String
    ) async throws -> FinancialConnectionsSession {
        // First, get the initial session
        let initialSession = try await sessionReceipt(clientSecret: clientSecret)

        // If there are no more accounts to fetch, return the session as is
        guard let accounts = initialSession.accounts, accounts.hasMore else {
            return initialSession
        }

        // Start with the accounts already in the session
        var allAccounts = accounts.data
        var hasMore = accounts.hasMore
        var lastAccountId = allAccounts.last?.id
        let maxNumberOfAccountsToFetch: Int = 100

        // Continue fetching accounts until there are no more or we've reached 100
        while hasMore && allAccounts.count < maxNumberOfAccountsToFetch {
            // Fetch next page of accounts
            let accountList = try await listAccounts(
                clientSecret: clientSecret,
                startingAfterAccountId: lastAccountId
            )

            // Add accounts to our collection
            allAccounts.append(contentsOf: accountList.data)

            // Update for next iteration
            hasMore = accountList.hasMore
            lastAccountId = accountList.data.last?.id
        }

        // Create a new AccountList with all the accounts we've fetched
        let completeAccountList = FinancialConnectionsSession.AccountList(
            data: allAccounts,
            hasMore: hasMore // Will be true if we hit the 100 account limit but there are more
        )

        // Create a new Session with the complete account list
        return FinancialConnectionsSession(
            id: initialSession.id,
            clientSecret: initialSession.clientSecret,
            livemode: initialSession.livemode,
            accounts: completeAccountList,
            paymentAccount: initialSession.paymentAccount
        )
    }

    private func sessionReceipt(
        clientSecret: String
    ) async throws -> FinancialConnectionsSession {
        let parameters: [String: Any] = [
            "client_secret": clientSecret,
        ]
        return try await get(endpoint: .sessionReceipt, parameters: parameters)
    }

    private func listAccounts(
        clientSecret: String,
        startingAfterAccountId: String?
    ) async throws -> FinancialConnectionsSession.AccountList {
        var parameters: [String: Any] = [
            "client_secret": clientSecret
        ]
        if let startingAfterAccountId = startingAfterAccountId {
            parameters["starting_after"] = startingAfterAccountId
        }
        return try await get(endpoint: .listAccounts, parameters: parameters)
    }
}
