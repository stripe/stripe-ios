//
//  FinancialConnectionsAPIClient.swift
//  StripeFinancialConnections
//
//  Created by Vardges Avetisyan on 12/1/21.
//

import Foundation
@_spi(STP) import StripeCore

protocol FinancialConnectionsAPIClient {

    func generateSessionManifest(clientSecret: String, returnURL: String?) -> Promise<FinancialConnectionsSessionManifest>

    func fetchFinancialConnectionsAccounts(clientSecret: String,
                                           startingAfterAccountId: String?) -> Promise<StripeAPI.FinancialConnectionsSession.AccountList>

    func fetchFinancialConnectionsSession(clientSecret: String) -> Promise<StripeAPI.FinancialConnectionsSession>
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

    func generateSessionManifest(clientSecret: String, returnURL: String?) -> Promise<FinancialConnectionsSessionManifest> {
        let body = FinancialConnectionsSessionsGenerateHostedUrlBody(clientSecret: clientSecret, fullscreen: true, hideCloseButton: true, appReturnUrl: returnURL)
        return self.post(resource: APIEndpointGenerateHostedURL,
                         object: body)
    }

}

private let APIEndpointListAccounts = "link_account_sessions/list_accounts"
private let APIEndpointSessionReceipt = "link_account_sessions/session_receipt"
private let APIEndpointGenerateHostedURL = "link_account_sessions/generate_hosted_url"
