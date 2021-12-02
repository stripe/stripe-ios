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
}

extension STPAPIClient: ConnectionsAPIClient {
    func generateLinkAccountSessionManifest(clientSecret: String) -> Promise<LinkAccountSessionManifest> {
        return self.post(resource: "link_account_sessions/generate_hosted_url",
                         object: LinkAccountSessionsGenerateHostedUrlBody(clientSecret: clientSecret, _additionalParametersStorage: nil),
                         ephemeralKeySecret: nil)
    }

}
