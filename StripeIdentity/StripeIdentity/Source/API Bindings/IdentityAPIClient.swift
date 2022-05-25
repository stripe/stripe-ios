//
//  IdentityAPIClient.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 10/26/21.
//

import Foundation
import UIKit
@_spi(STP) import StripeCore

protocol IdentityAPIClient {
    var verificationSessionId: String { get }

    func getIdentityVerificationPage() -> Promise<VerificationPage>

    func updateIdentityVerificationPageData(
        updating verificationData: VerificationPageDataUpdate
    ) -> Promise<VerificationPageData>

    func submitIdentityVerificationPage() -> Promise<VerificationPageData>

    func uploadImage(
        _ image: UIImage,
        compressionQuality: CGFloat,
        purpose: String,
        fileName: String
    ) -> Promise<StripeFile>
}

final class IdentityAPIClientImpl: IdentityAPIClient {
    static let apiVersion: Int = 1

    static var betas: Set<String> {
        return ["identity_client_api=v\(apiVersion)"]
    }

    let apiClient: STPAPIClient
    let verificationSessionId: String

    private init(
        verificationSessionId: String,
        apiClient: STPAPIClient
    ) {
        self.verificationSessionId = verificationSessionId
        self.apiClient = apiClient
    }

    convenience init(
        verificationSessionId: String,
        ephemeralKeySecret: String
    ) {
        let apiClient = STPAPIClient(publishableKey: ephemeralKeySecret)
        apiClient.betas = IdentityAPIClientImpl.betas
        apiClient.appInfo = STPAPIClient.shared.appInfo

        self.init(
            verificationSessionId: verificationSessionId,
            apiClient: apiClient
        )
    }

    func getIdentityVerificationPage() -> Promise<VerificationPage> {
        return apiClient.get(
            resource: APIEndpointVerificationPage(id: verificationSessionId),
            parameters: [:]
        )
    }

    func updateIdentityVerificationPageData(
        updating verificationData: VerificationPageDataUpdate
    ) -> Promise<VerificationPageData> {
        return apiClient.post(
            resource: APIEndpointVerificationPageData(id: verificationSessionId),
            object: verificationData
        )
    }

    func submitIdentityVerificationPage() -> Promise<VerificationPageData> {
        return apiClient.post(
            resource: APIEndpointVerificationPageSubmit(id: verificationSessionId),
            parameters: [:]
        )
    }

    func uploadImage(
        _ image: UIImage,
        compressionQuality: CGFloat,
        purpose: String,
        fileName: String
    ) -> Promise<StripeFile> {
        return apiClient.uploadImage(
            image,
            compressionQuality: compressionQuality,
            purpose: purpose,
            fileName: fileName,
            ownedBy: verificationSessionId
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
