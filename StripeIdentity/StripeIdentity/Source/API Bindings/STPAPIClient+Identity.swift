//
//  STPAPIClient+Identity.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 10/26/21.
//

import Foundation
import UIKit
@_spi(STP) import StripeCore

protocol IdentityAPIClient {
    func getIdentityVerificationPage(
        id: String,
        ephemeralKeySecret: String
    ) -> Promise<VerificationPage>

    func updateIdentityVerificationSessionData(
        id: String,
        updating verificationData: VerificationSessionDataUpdate,
        ephemeralKeySecret: String
    ) -> Promise<VerificationSessionData>

    func submitIdentityVerificationSession(
        id: String,
        ephemeralKeySecret: String
    ) -> Promise<VerificationSessionData>

    func uploadImage(
        _ image: UIImage,
        purpose: StripeFile.Purpose
    ) -> Promise<StripeFile>
}

extension STPAPIClient: IdentityAPIClient {
    /// Instantiates an `IdentityAPIClient` with the API version used by this SDK version
    static func makeIdentityClient() -> IdentityAPIClient {
        let client = STPAPIClient()
        client.betas = [
            "identity_client_api=v1"
        ]
        return client
    }

    func getIdentityVerificationPage(
        id: String,
        ephemeralKeySecret: String
    ) -> Promise<VerificationPage> {
        return self.get(
            resource: APIEndpointVerificationPage(id: id),
            parameters: [:],
            ephemeralKeySecret: ephemeralKeySecret
        )
    }

    func updateIdentityVerificationSessionData(
        id: String,
        updating verificationData: VerificationSessionDataUpdate,
        ephemeralKeySecret: String
    ) -> Promise<VerificationSessionData> {
        return self.post(
            resource: APIEndpointVerificationSessionData(id: id),
            object: verificationData,
            ephemeralKeySecret: ephemeralKeySecret
        )
    }

    func submitIdentityVerificationSession(
        id: String,
        ephemeralKeySecret: String
    ) -> Promise<VerificationSessionData> {
        return self.post(
            resource: APIEndpointVerificationSessionSubmit(id: id),
            parameters: [:],
            ephemeralKeySecret: ephemeralKeySecret
        )
    }
}

private func APIEndpointVerificationPage(id: String) -> String {
    return "identity/verification_pages/\(id)"
}

// TODO(mludowise|IDPROD-2884): Rename variables and types to match new endpoint names
private func APIEndpointVerificationSessionData(id: String) -> String {
    return "identity/verification_pages/\(id)/data"
}
private func APIEndpointVerificationSessionSubmit(id: String) -> String {
    return "identity/verification_pages/\(id)/submit"
}
