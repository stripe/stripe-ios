//
//  AccountPickerAPIClient.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 8/5/22.
//

import Foundation
@_spi(STP) import StripeCore

protocol AccountPickerAPIClient: AnyObject {
    func pollOAuthResults(completionHandler: @escaping () -> Void)
}

final class AccountPickerAPIClientImplementation: AccountPickerAPIClient {
    
    private let apiClient: FinancialConnectionsAPIClient
    private let clientString: String
    private let authorizationSession: FinancialConnectionsAuthorizationSession
    
    init(
        apiClient: FinancialConnectionsAPIClient,
        clientSecret: String,
        authorizationSession: FinancialConnectionsAuthorizationSession
    ) {
        self.apiClient = apiClient
        self.clientString = clientSecret
        self.authorizationSession = authorizationSession
    }
    
    // TODO: Maybe combine it with authorize
    func pollOAuthResults(completionHandler: @escaping () -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
            guard let self = self else { return }
            
            self.apiClient.fetchAuthSessionOAuthResults(
                clientSecret: self.clientString,
                authSessionId: self.authorizationSession.id
            )
            .observe(on: DispatchQueue.main) { result in
    //            guard let self = self else { return }
    //            guard lastInstitutionSearchFetchDate == self.lastInstitutionSearchFetchDate else {
    //                // ignore any search result that came before
    //                // the lastest search attempt
    //                return
    //            }
                
                switch result {
                case .success(let parameters):
                    print(parameters)
                    // FinancialConnectionsMixedOAuthParams(state: "bcsess_1LTXaOL6p1bboFUQXNiU9ZTP", code: Optional("success"), status: nil, memberGuid: nil, error: nil)
                    
                    
                    
                    self.apiClient.authorizeAuthSession(
                        clientSecret: self.clientString,
                        authSessionId: self.authorizationSession.id,
                        publicToken: parameters.memberGuid
                    )
                    .observe(on: DispatchQueue.main) { [weak self] result in
                        guard let self = self else { return }
                        switch result {
                        case .success(let authorizationSession):
                            print(authorizationSession)
                            
                            self.apiClient.fetchAuthSessionAccounts(
                                clientSecret: self.clientString,
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
