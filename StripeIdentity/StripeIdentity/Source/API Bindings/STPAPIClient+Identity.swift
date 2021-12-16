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

    func updateIdentityVerificationPageData(
        id: String,
        updating verificationData: VerificationPageDataUpdate,
        ephemeralKeySecret: String
    ) -> Promise<VerificationPageData>

    func submitIdentityVerificationPage(
        id: String,
        ephemeralKeySecret: String
    ) -> Promise<VerificationPageData>

    func uploadImage(
        _ image: UIImage,
        compressionQuality: CGFloat,
        purpose: String,
        fileName: String,
        ownedBy: String?,
        ephemeralKeySecret: String?
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

    func updateIdentityVerificationPageData(
        id: String,
        updating verificationData: VerificationPageDataUpdate,
        ephemeralKeySecret: String
    ) -> Promise<VerificationPageData> {
        return self.post(
            resource: APIEndpointVerificationPageData(id: id),
            object: verificationData,
            ephemeralKeySecret: ephemeralKeySecret
        )
    }

    func submitIdentityVerificationPage(
        id: String,
        ephemeralKeySecret: String
    ) -> Promise<VerificationPageData> {
        return self.post(
            resource: APIEndpointVerificationPageSubmit(id: id),
            parameters: [:],
            ephemeralKeySecret: ephemeralKeySecret
        )
    }
}

private func APIEndpointVerificationPage(id: String) -> String {
    return "identity/verification_pages/\(id)"
}
private func APIEndpointVerificationPageData(id: String) -> String {
    return "identity/verification_pages/\(id)/data"
}
private func APIEndpointVerificationPageSubmit(id: String) -> String {
    return "identity/verification_pages/\(id)/submit"
}
