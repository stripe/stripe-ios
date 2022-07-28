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
    
    func fetchFeaturedInstitutions(clientSecret: String) -> Promise<FinancialConnectionsInstitutionList>
    
    func fetchInstitutions(clientSecret: String, query: String) -> Promise<FinancialConnectionsInstitutionList>
    
    func createAuthorizationSession(clientSecret: String, institutionId: String) -> Promise<FinancialConnectionsAuthorizationSession>
    
    func authorizeAuthSession(clientSecret: String,
                              authSessionId: String,
                              publicToken: String?) -> Promise<FinancialConnectionsAuthorizationSession>
    
    func fetchAuthSessionAccounts(clientSecret: String, authSessionId: String) -> Promise<FinancialConnectionsAuthorizationSessionAccounts>
    
    func selectAuthSessionAccounts(clientSecret: String,
                                   authSessionId: String,
                                   selectedAccountIds: [String]) -> Promise<FinancialConnectionsAuthorizationSessionAccounts>
    
    func markLinkingMoreAccounts(clientSecret: String) -> Promise<FinancialConnectionsSessionManifest>
    
    func completeLinkAccountSession(clientSecret: String) -> Promise<StripeAPI.FinancialConnectionsSession>
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
        return self.post(resource: APIEndpointConsentAcquired, object: body)
    }

    func fetchFeaturedInstitutions(clientSecret: String) -> Promise<FinancialConnectionsInstitutionList> {
        let parameters = [
            "client_secret": clientSecret,
            "limit": "10"
        ]
        return self.get(resource: APIEndpointFeaturedInstitutions,
                        parameters: parameters)
    }
    
    func fetchInstitutions(clientSecret: String, query: String) -> Promise<FinancialConnectionsInstitutionList> {
        let parameters = [
            "client_secret": clientSecret,
            "query": query,
            "limit": "20"
        ]
        return self.get(resource: APIEndpointSearchInstitutions,
                        parameters: parameters)
    }
    
    func createAuthorizationSession(clientSecret: String, institutionId: String) -> Promise<FinancialConnectionsAuthorizationSession> {
        let body = [
            "client_secret": clientSecret,
            "institution": institutionId,
            "use_mobile_handoff": "false"
        ]
        return self.post(resource: APIEndpointAuthorizationSessions, object: body)
    }
    
    func authorizeAuthSession(clientSecret: String,
                              authSessionId: String,
                              publicToken: String? = nil) -> Promise<FinancialConnectionsAuthorizationSession> {
        var body = [
            "client_secret": clientSecret,
            "id": authSessionId,
        ]
        body["public_token"] = nil // not all integrations require public_token
        return self.post(resource: APIEndpointAuthorizationSessionsAuthorized, object: body)
    }
    
    func fetchAuthSessionAccounts(clientSecret: String, authSessionId: String) -> Promise<FinancialConnectionsAuthorizationSessionAccounts> {
        let body = [
            "client_secret": clientSecret,
            "id": authSessionId,
        ]
        return self.post(resource: APIEndpointAuthorizationSessionsAccounts, object: body)
    }
    
    func selectAuthSessionAccounts(clientSecret: String,
                                   authSessionId: String,
                                   selectedAccountIds: [String]) -> Promise<FinancialConnectionsAuthorizationSessionAccounts> {
        let body: [String: Any] = [
            "client_secret": clientSecret,
            "id": authSessionId,
            "selected_accounts": selectedAccountIds,
        ]
        return self.post(resource: APIEndpointAuthorizationSessionsSelectedAccounts, parameters: body)
    }
    
    func markLinkingMoreAccounts(clientSecret: String) -> Promise<FinancialConnectionsSessionManifest> {
        let body = [
            "client_secret": clientSecret,
        ]
        return self.post(resource: APIEndpointLinkMoreAccounts, object: body)
    }
    
    func completeLinkAccountSession(clientSecret: String) -> Promise<StripeAPI.FinancialConnectionsSession> {
        let body = [
            "client_secret": clientSecret,
        ]
        return self.post(resource: APIEndpointComplete, object: body)
    }
}

private let APIEndpointListAccounts = "link_account_sessions/list_accounts"
private let APIEndpointSessionReceipt = "link_account_sessions/session_receipt"
private let APIEndpointGenerateHostedURL = "link_account_sessions/generate_hosted_url"
private let APIEndpointConsentAcquired = "link_account_sessions/consent_acquired"
private let APIEndpointLinkMoreAccounts = "link_account_sessions/link_more_accounts"
private let APIEndpointComplete = "link_account_sessions/complete"
private let APIEndpointFeaturedInstitutions = "connections/featured_institutions"
private let APIEndpointSearchInstitutions = "connections/institutions"
private let APIEndpointAuthorizationSessions = "connections/auth_sessions"
private let APIEndpointAuthorizationSessionsAuthorized = "connections/auth_sessions/authorized"
private let APIEndpointAuthorizationSessionsAccounts = "connections/auth_sessions/accounts"
private let APIEndpointAuthorizationSessionsSelectedAccounts = "connections/auth_sessions/selected_accounts"
