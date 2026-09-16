//
//  IdentityAPIClient.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 10/26/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore
import UIKit

protocol IdentityAPIClient: AnyObject {
    var verificationSessionId: String { get }
    var supportsNetworkedIdentity: Bool { get }

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

    func verifyTestVerificationSession(
        simulateDelay: Bool
    ) -> Promise<StripeAPI.VerificationPageData>

    func unverifyTestVerificationSession(
        simulateDelay: Bool
    ) -> Promise<StripeAPI.VerificationPageData>

    func generatePhoneOtp() -> Promise<StripeAPI.VerificationPageData>

    func cannotPhoneVerifyOtp() -> Promise<StripeAPI.VerificationPageData>

    func attachNetworkedIdentityDocument(
        associationToken: String
    ) -> Promise<StripeAPI.VerificationPageData>

    func prepareNetworkedIdentityDocumentSave(
        associationToken: String
    ) -> Promise<StripeAPI.VerificationPageData>

    func skipNetworkedIdentity() -> Promise<StripeAPI.VerificationPageData>
}

enum IdentityAPIClientError: Error {
    case networkedIdentityRequiresV8
}

final class IdentityAPIClientImpl: IdentityAPIClient {
    /// The latest production-ready version of the VerificationPages API that the
    /// SDK is capable of using.
    ///
    /// - Note: Update this value when a new API version is ready for use in production.
    static let productionApiVersion: Int = 7

    var betas: Set<String> {
        return ["identity_client_api=v\(apiVersion)"]
    }

    let apiClient: STPAPIClient
    let verificationSessionId: String

    var supportsNetworkedIdentity: Bool {
        apiVersion >= 8
    }

    /// The VerificationPages API version used to make all API requests.
    ///
    /// - Note: This should only be modified when testing endpoints not yet in production.
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
            parameters: ["app_identifier": Bundle.main.bundleIdentifier ?? ""]
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

    func verifyTestVerificationSession(simulateDelay: Bool) -> Promise<StripeAPI.VerificationPageData> {
        return apiClient.post(
            resource: APIEndpointVerificationPageTestingVerify(id: verificationSessionId),
            parameters: ["simulate_delay": simulateDelay]
        )
    }

    func unverifyTestVerificationSession(simulateDelay: Bool) -> Promise<StripeAPI.VerificationPageData> {
        return apiClient.post(
            resource: APIEndpointVerificationPageTestingUnverify(id: verificationSessionId),
            parameters: ["simulate_delay": simulateDelay]
        )
    }

    func generatePhoneOtp() -> StripeCore.Promise<StripeCore.StripeAPI.VerificationPageData> {
        return apiClient.post(
            resource: APIEndpointVerificationPagePhoneOtpGenerate(id: verificationSessionId),
            parameters: [:]
        )
    }

    func cannotPhoneVerifyOtp() -> StripeCore.Promise<StripeCore.StripeAPI.VerificationPageData> {
        return apiClient.post(
            resource: APIEndpointVerificationPagePhoneOtpCannotVerify(id: verificationSessionId),
            parameters: [:]
        )
    }

    func attachNetworkedIdentityDocument(
        associationToken: String
    ) -> Promise<StripeAPI.VerificationPageData> {
        postNetworkedIdentityAction(
            "attach_document",
            parameters: ["identity_document_association_token": associationToken]
        )
    }

    func prepareNetworkedIdentityDocumentSave(
        associationToken: String
    ) -> Promise<StripeAPI.VerificationPageData> {
        postNetworkedIdentityAction(
            "prepare_document_save",
            parameters: ["identity_document_save_association_token": associationToken]
        )
    }

    func skipNetworkedIdentity() -> Promise<StripeAPI.VerificationPageData> {
        postNetworkedIdentityAction("skip", parameters: [:])
    }

    private func postNetworkedIdentityAction(
        _ action: String,
        parameters: [String: Any]
    ) -> Promise<StripeAPI.VerificationPageData> {
        guard supportsNetworkedIdentity else {
            return Promise(error: IdentityAPIClientError.networkedIdentityRequiresV8)
        }

        // #TODO - Networked Identity: Confirm the draft v8 action paths and VerificationPageData response before rollout.
        let resource = "identity/verification_pages/\(verificationSessionId)/networked_identity/\(action)"
        let formData = URLEncoder.queryString(from: parameters).data(using: .utf8)
        var request = apiClient.configuredRequest(
            for: apiClient.apiURL.appendingPathComponent(resource),
            additionalHeaders: [
                "Content-Length": String(formData?.count ?? 0),
                "Content-Type": "application/x-www-form-urlencoded",
            ]
        )
        request.httpMethod = "POST"
        request.httpBody = formData

        // Association tokens are single-use. Never automatically replay a mutation after an ambiguous response.
        let promise = Promise<StripeAPI.VerificationPageData>()
        let task = apiClient.urlSession.dataTask(with: request) { data, response, error in
            let result: Result<StripeAPI.VerificationPageData, Error> = STPAPIClient.decodeResponse(
                data: data,
                error: error,
                response: response,
                request: nil
            )
            DispatchQueue.main.async {
                promise.fullfill(with: result)
            }
        }
        task.resume()
        return promise
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
private func APIEndpointVerificationPageTestingVerify(id: String) -> String {
    return "identity/verification_pages/\(id)/testing/verify"
}
private func APIEndpointVerificationPageTestingUnverify(id: String) -> String {
    return "identity/verification_pages/\(id)/testing/unverify"
}
private func APIEndpointVerificationPagePhoneOtpGenerate(id: String) -> String {
    return "identity/verification_pages/\(id)/phone_otp/generate"
}
private func APIEndpointVerificationPagePhoneOtpCannotVerify(id: String) -> String {
    return "identity/verification_pages/\(id)/phone_otp/cannot_verify"
}
