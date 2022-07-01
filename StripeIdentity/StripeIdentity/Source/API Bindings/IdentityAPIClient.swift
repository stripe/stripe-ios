//
//  IdentityAPIClient.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 10/26/21.
//

import Foundation
import UIKit
@_spi(STP) import StripeCore

protocol IdentityAPIClient: AnyObject {
    var verificationSessionId: String { get }
    var apiVersion: Int { get set }

    func getIdentityVerificationPage() -> Promise<StripeAPI.VerificationPage>

    func updateIdentityVerificationPageData(
        updating verificationData: StripeAPI.VerificationPageDataUpdate
    ) -> Promise<StripeAPI.VerificationPageData>

    func submitIdentityVerificationPage() -> Promise<StripeAPI.VerificationPageData>

    func uploadImage(
        _ image: UIImage,
        compressionQuality: CGFloat,
        purpose: String,
        fileName: String
    ) -> Future<STPAPIClient.FileAndUploadMetrics>
}

final class IdentityAPIClientImpl: IdentityAPIClient {
    /**
     The latest production-ready version of the VerificationPages API that the
     SDK is capable of using.

     - Note: Update this value when a new API version is ready for use in production.
     */
    static let productionApiVersion: Int = 2

    var betas: Set<String> {
        return ["identity_client_api=v\(apiVersion)"]
    }

    let apiClient: STPAPIClient
    let verificationSessionId: String

    /**
     The VerificationPages API version used to make all API requests.

     - Note: This should only be modified when testing endpoints not yet in production.
     */
    var apiVersion = IdentityAPIClientImpl.productionApiVersion {
        didSet {
            apiClient.betas = betas
        }
    }

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
        self.init(
            verificationSessionId: verificationSessionId,
            apiClient: STPAPIClient(publishableKey: ephemeralKeySecret)
        )
        apiClient.betas = betas
        apiClient.appInfo = STPAPIClient.shared.appInfo
    }

    func getIdentityVerificationPage() -> Promise<StripeAPI.VerificationPage> {
        return apiClient.get(
            resource: APIEndpointVerificationPage(id: verificationSessionId),
            parameters: [:]
        )
    }

    func updateIdentityVerificationPageData(
        updating verificationData: StripeAPI.VerificationPageDataUpdate
    ) -> Promise<StripeAPI.VerificationPageData> {
        return apiClient.post(
            resource: APIEndpointVerificationPageData(id: verificationSessionId),
            object: verificationData
        )
    }

    func submitIdentityVerificationPage() -> Promise<StripeAPI.VerificationPageData> {
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
    ) -> Future<STPAPIClient.FileAndUploadMetrics> {
        return apiClient.uploadImageAndGetMetrics(
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
