//
//  AccountPickerDataSource.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 8/5/22.
//

import Foundation
@_spi(STP) import StripeCore

protocol AccountPickerDataSource: AnyObject {
    func pollAuthSessionAccounts() -> Promise<FinancialConnectionsAuthorizationSessionAccounts>
}

final class AccountPickerDataSourceImplementation: AccountPickerDataSource {
    
    private let apiClient: FinancialConnectionsAPIClient
    private let clientSecret: String
    private let authorizationSession: FinancialConnectionsAuthorizationSession
    
    init(
        apiClient: FinancialConnectionsAPIClient,
        clientSecret: String,
        authorizationSession: FinancialConnectionsAuthorizationSession
    ) {
        self.apiClient = apiClient
        self.clientSecret = clientSecret
        self.authorizationSession = authorizationSession
    }
    
    func pollAuthSessionAccounts() -> Promise<FinancialConnectionsAuthorizationSessionAccounts> {
        let promise = Promise<FinancialConnectionsAuthorizationSessionAccounts>()
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in // TODO(kgaidis): implement polling instead of a delay
            guard let self = self else { return }
            self.apiClient.fetchAuthSessionAccounts(
                clientSecret: self.clientSecret,
                authSessionId: self.authorizationSession.id
            )
            .observe(on: DispatchQueue.main) { result in
                promise.fullfill(with: result)
            }
        }
        return promise
    }
}
