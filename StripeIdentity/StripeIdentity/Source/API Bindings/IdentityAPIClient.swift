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

    func getIdentityVerificationPage() async throws -> StripeAPI.VerificationPage

    func updateIdentityVerificationPageData(
        updating verificationData: StripeAPI.VerificationPageDataUpdate
    ) async throws -> StripeAPI.VerificationPageData

    func submitIdentityVerificationPage() async throws -> StripeAPI.VerificationPageData

    func uploadImage(
        _ image: UIImage,
        compressionQuality: CGFloat,
        purpose: String,
        fileName: String
    ) async throws -> STPAPIClient.FileAndUploadMetrics

    func verifyTestVerificationSession(
        simulateDelay: Bool
    ) async throws -> StripeAPI.VerificationPageData

    func unverifyTestVerificationSession(
        simulateDelay: Bool
    ) async throws -> StripeAPI.VerificationPageData

    func generatePhoneOtp() async throws -> StripeAPI.VerificationPageData

    func cannotPhoneVerifyOtp() async throws -> StripeAPI.VerificationPageData
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

    func getIdentityVerificationPage() async throws -> StripeAPI.VerificationPage {
        try await apiClient.get(
            resource: APIEndpointVerificationPage(id: verificationSessionId),
            parameters: ["app_identifier": Bundle.main.bundleIdentifier ?? ""]
        )
    }

    func updateIdentityVerificationPageData(
        updating verificationData: StripeAPI.VerificationPageDataUpdate
    ) async throws -> StripeAPI.VerificationPageData {
        try await apiClient.post(
            resource: APIEndpointVerificationPageData(id: verificationSessionId),
            object: verificationData
        )
    }

    func submitIdentityVerificationPage() async throws -> StripeAPI.VerificationPageData {
        try await apiClient.post(
            resource: APIEndpointVerificationPageSubmit(id: verificationSessionId),
            parameters: [:]
        )
    }

    func uploadImage(
        _ image: UIImage,
        compressionQuality: CGFloat,
        purpose: String,
        fileName: String
    ) async throws -> STPAPIClient.FileAndUploadMetrics {
        return try await apiClient.uploadImageAndGetMetrics(
            image,
            compressionQuality: compressionQuality,
            purpose: purpose,
            fileName: fileName,
            ownedBy: verificationSessionId
        )
    }

    func verifyTestVerificationSession(simulateDelay: Bool) async throws -> StripeAPI.VerificationPageData {
        try await apiClient.post(
            resource: APIEndpointVerificationPageTestingVerify(id: verificationSessionId),
            parameters: ["simulate_delay": simulateDelay]
        )
    }

    func unverifyTestVerificationSession(simulateDelay: Bool) async throws -> StripeAPI.VerificationPageData {
        try await apiClient.post(
            resource: APIEndpointVerificationPageTestingUnverify(id: verificationSessionId),
            parameters: ["simulate_delay": simulateDelay]
        )
    }

    func generatePhoneOtp() async throws -> StripeCore.StripeAPI.VerificationPageData {
        try await apiClient.post(
            resource: APIEndpointVerificationPagePhoneOtpGenerate(id: verificationSessionId),
            parameters: [:]
        )
    }

    func cannotPhoneVerifyOtp() async throws -> StripeCore.StripeAPI.VerificationPageData {
        try await apiClient.post(
            resource: APIEndpointVerificationPagePhoneOtpCannotVerify(id: verificationSessionId),
            parameters: [:]
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
