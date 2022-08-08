//
//  AccountPickerDataSource.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 8/5/22.
//

import Foundation
@_spi(STP) import StripeCore

protocol AccountPickerDataSource: AnyObject {
    func pollOAuthResults(completionHandler: @escaping () -> Void)
    func establishConnection() -> Promise<Void>
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
    
    func establishConnection() -> Promise<Void> {
        let promise = Promise<Void>()
        
        let clientSecret = self.clientSecret
        let authorizationSession = authorizationSession
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
            guard let self = self else { return }
            self.apiClient.fetchAuthSessionOAuthResults(
                clientSecret: self.clientSecret,
                authSessionId: self.authorizationSession.id
            )
            .chained(on: DispatchQueue.main, using: { params in
                return self.apiClient.authorizeAuthSession(
                    clientSecret: clientSecret,
                    authSessionId: authorizationSession.id,
                    publicToken: params.memberGuid
                )
            })
            .observe(on: DispatchQueue.main) { result in
                promise.fullfill(with: result.map( { _ in () }  ))
            }
        }
        
        return promise
    }
    
    // TODO: Maybe combine it with authorize
    func pollOAuthResults(completionHandler: @escaping () -> Void) {
        
        
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
            guard let self = self else { return }
            
            self.apiClient.fetchAuthSessionOAuthResults(
                clientSecret: self.clientSecret,
                authSessionId: self.authorizationSession.id
            )
            .observe(on: DispatchQueue.main) { result in
                switch result {
                case .success(let parameters):
                    print(parameters)
                    self.apiClient.authorizeAuthSession(
                        clientSecret: self.clientSecret,
                        authSessionId: self.authorizationSession.id,
                        publicToken: parameters.memberGuid
                    )
                    .observe(on: DispatchQueue.main) { [weak self] result in
                        guard let self = self else { return }
                        switch result {
                        case .success(let authorizationSession):
                            print(authorizationSession)
                            
                            self.apiClient.fetchAuthSessionAccounts(
                                clientSecret: self.clientSecret,
                                authSessionId: authorizationSession.id
                            ).observe(on: DispatchQueue.main) { result in
//                                guard let self = self else { return }
                                switch result {
                                case .success(let accounts):
                                    print(accounts)
                                    break
                                case .failure(let error):
                                    print(error)
                                    break
                                }
                            }
                            
                            break
                        case .failure(let error):
                            print(error)
                            break
                        }
                    }
                    
                    
                    break
                case .failure(let error):
                    print(error)
                    break
                }
                
    //            switch(result) {
    //            case .success(let institutions):
    //                self.institutionSearchTableView.loadInstitutions(institutions)
    //            case .failure(let error):
    //                // TODO(kgaidis): handle search error
    //                print(error)
    //            }
            }
        }
    }
    
    private func authorize(completionHandler: @escaping () -> Void) {
        
    }
}
