//
//  PartnerAuthDataSource.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 8/8/22.
//

import Foundation

import Foundation
@_spi(STP) import StripeCore

enum PartnerAuthPaneType {
    case success(FinancialConnectionsAuthorizationSession)
    case error(Error)
}

protocol PartnerAuthDataSource: AnyObject {
    var institution: FinancialConnectionsInstitution { get }
    var paneType: PartnerAuthPaneType { get }
    
    func authorizeAuthSession(_ authorizationSession: FinancialConnectionsAuthorizationSession) -> Promise<Void>
}

final class PartnerAuthDataSourceImplementation: PartnerAuthDataSource {
    
    let institution: FinancialConnectionsInstitution
    let paneType: PartnerAuthPaneType
    private let apiClient: FinancialConnectionsAPIClient
    private let clientSecret: String
    
    init(
        institution: FinancialConnectionsInstitution,
        paneType: PartnerAuthPaneType,
        apiClient: FinancialConnectionsAPIClient,
        clientSecret: String
    ) {
        self.institution = institution
        self.paneType = paneType
        self.apiClient = apiClient
        self.clientSecret = clientSecret
    }
    
    func authorizeAuthSession(_ authorizationSession: FinancialConnectionsAuthorizationSession) -> Promise<Void> {
        let promise = Promise<Void>()
        let clientSecret = self.clientSecret
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in // TODO(kgaidis): implement polling instead of a delay
            guard let self = self else { return }
            self.apiClient.fetchAuthSessionOAuthResults(
                clientSecret: clientSecret,
                authSessionId: authorizationSession.id
            )
            .chained(on: DispatchQueue.main, using: { mixedOAuthParameters in
                return self.apiClient.authorizeAuthSession(
                    clientSecret: clientSecret,
                    authSessionId: authorizationSession.id,
                    publicToken: mixedOAuthParameters.memberGuid
                )
            })
            .observe(on: DispatchQueue.main) { result in
                promise.fullfill(with: result.map({ _ in () }))
            }
        }
        return promise
    }
}
