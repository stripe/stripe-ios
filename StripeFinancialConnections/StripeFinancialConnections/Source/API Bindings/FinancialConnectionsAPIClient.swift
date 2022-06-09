//
//  FinancialConnectionsAPIClient.swift
//  StripeFinancialConnections
//
//  Created by Vardges Avetisyan on 12/1/21.
//

import Foundation
@_spi(STP) import StripeCore

protocol FinancialConnectionsAPIClient {

    func generateSessionManifest(clientSecret: String) -> Promise<FinancialConnectionsSessionManifest>

    func fetchFinancialConnectionsAccounts(clientSecret: String,
                                           startingAfterAccountId: String?) -> Promise<StripeAPI.FinancialConnectionsSession.AccountList>

    func fetchFinancialConnectionsSession(clientSecret: String) -> Promise<StripeAPI.FinancialConnectionsSession>
    
    func markConsentAcquired(clientSecret: String) -> Promise<FinancialConnectionsSessionManifest>
}

extension STPAPIClient: FinancialConnectionsAPIClient {

    func fetchFinancialConnectionsAccounts(clientSecret: String,
                                           startingAfterAccountId: String?) -> Promise<StripeAPI.FinancialConnectionsSession.AccountList> {
        var parameters = ["client_secret": clientSecret]
        if let startingAfterAccountId = startingAfterAccountId {
            parameters["starting_after"] = startingAfterAccountId
        }
        return self.get(resource: APIEndpointListAccounts,
                        parameters: parameters)
    }

    func fetchFinancialConnectionsSession(clientSecret: String) -> Promise<StripeAPI.FinancialConnectionsSession> {
        return self.get(resource: APIEndpointSessionReceipt,
                        parameters: ["client_secret": clientSecret])
    }

    func generateSessionManifest(clientSecret: String) -> Promise<FinancialConnectionsSessionManifest> {
        let body = FinancialConnectionsSessionsGenerateHostedUrlBody(clientSecret: clientSecret, fullscreen: true, hideCloseButton: true)
        return self.post(resource: APIEndpointGenerateHostedURL,
                         object: body)
    }
    
    func markConsentAcquired(clientSecret: String) -> Promise<FinancialConnectionsSessionManifest> {
        let body = FinancialConnectionsSessionsClientSecretBody(clientSecret: clientSecret)
        return self.post(resource: APIEndpointConsentAcquiredURL, object: body)
    }

}

private let APIEndpointListAccounts = "link_account_sessions/list_accounts"
private let APIEndpointSessionReceipt = "link_account_sessions/session_receipt"
private let APIEndpointGenerateHostedURL = "link_account_sessions/generate_hosted_url"
private let APIEndpointConsentAcquiredURL = "link_account_sessions/consent_acquired"
