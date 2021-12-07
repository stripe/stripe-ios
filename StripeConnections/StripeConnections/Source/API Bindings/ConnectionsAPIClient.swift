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

    func fetchLinkedAccounts(clientSecret: String) -> Promise<[StripeAPI.LinkedAccount]>
}

extension STPAPIClient: ConnectionsAPIClient {

    func fetchLinkedAccounts(clientSecret: String) -> Promise<[StripeAPI.LinkedAccount]> {
        let promise = Promise<[StripeAPI.LinkedAccount]>()
        let session = URLSession.shared
        let url = URL(string: "https://desert-instinctive-eoraptor.glitch.me/linked_accounts?las_client_secret=\(clientSecret)")!
        let urlRequest = URLRequest(url: url)
        let task = session.dataTask(with: urlRequest) { data, response, error in
            print("DATA \(String(describing: data)) res \(String(describing: response)) error: \(String(describing: error))")
            print("DATA: \(String(data: data!, encoding: .utf8) ?? "NIL")")

            DispatchQueue.main.async {
                guard
                    error == nil,
                    let data = data,
                    let responseJson = try? JSONDecoder().decode([StripeAPI.LinkedAccount].self, from: data)
                else {
                    promise.reject(with: ConnectionsSheetError.unknown(debugDescription: "Failed"))
                    return
                }

                promise.resolve(with: responseJson)
             }
        }
        task.resume()
        return promise
    }

    func generateLinkAccountSessionManifest(clientSecret: String) -> Promise<LinkAccountSessionManifest> {
        return self.post(resource: "link_account_sessions/generate_hosted_url",
                         object: LinkAccountSessionsGenerateHostedUrlBody(clientSecret: clientSecret, _additionalParametersStorage: nil))
    }

}
