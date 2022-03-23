//
//  ConnectionsAPIClient.swift
//  StripeConnections
//
//  Created by Vardges Avetisyan on 12/1/21.
//

import Foundation
@_spi(STP) import StripeCore

protocol ConnectionsAPIClient {

    func generateLinkAccountSessionManifest(clientSecret: String) -> Promise<LinkAccountSessionManifest>

    func fetchLinkedAccounts(clientSecret: String,
                             startingAfterAccountId: String?) -> Promise<StripeAPI.LinkedAccountList>

    func fetchLinkedAccountSession(clientSecret: String) -> Promise<StripeAPI.LinkAccountSession>
}

extension STPAPIClient: ConnectionsAPIClient {

    func fetchLinkedAccounts(clientSecret: String,
                             startingAfterAccountId: String?) -> Promise<StripeAPI.LinkedAccountList> {
        var parameters = ["client_secret": clientSecret]
        if let startingAfterAccountId = startingAfterAccountId {
            parameters["starting_after"] = startingAfterAccountId
        }
        return self.get(resource: APIEndpointListAccounts,
                        parameters: parameters)
    }

    func fetchLinkedAccountSession(clientSecret: String) -> Promise<StripeAPI.LinkAccountSession> {
        return self.get(resource: APIEndpointSessionReceipt,
                        parameters: ["client_secret": clientSecret])
    }

    func generateLinkAccountSessionManifest(clientSecret: String) -> Promise<LinkAccountSessionManifest> {
        return self.post(resource: APIEndpointGenerateHostedURL,
                         object: LinkAccountSessionsGenerateHostedUrlBody(clientSecret: clientSecret, _additionalParametersStorage: nil))
    }

}

fileprivate let APIEndpointListAccounts = "link_account_sessions/list_accounts"
fileprivate let APIEndpointSessionReceipt = "link_account_sessions/session_receipt"
fileprivate let APIEndpointGenerateHostedURL = "link_account_sessions/generate_hosted_url"
