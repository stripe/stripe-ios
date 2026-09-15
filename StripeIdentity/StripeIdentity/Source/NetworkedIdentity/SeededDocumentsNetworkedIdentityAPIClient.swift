//
//  SeededDocumentsNetworkedIdentityAPIClient.swift
//  StripeIdentity
//

import Foundation
@_spi(STP) import StripeCore
import UIKit

// #TODO - Networked Identity [NI-Contract]: remove once test-mode accounts with saved documents exist.

/// Debug-only: returns sample saved documents, because test-mode Link accounts can't have any.
/// Every other call goes to `delegate`.
final class SeededDocumentsNetworkedIdentityAPIClient: NetworkedIdentityAPIClient {
    static let seededIDPrefix = "seeded_iddoc_"
    static let seededTokenPrefix = "seeded_token_"
    static let seededSaveToken = seededTokenPrefix + "save"
    private static let secondsUntilExpiration = 365 * 24 * 60 * 60

    private let delegate: NetworkedIdentityAPIClient
    private let currentTime: () -> Int

    init(
        delegate: NetworkedIdentityAPIClient,
        currentTime: @escaping () -> Int = { Int(Date().timeIntervalSince1970) }
    ) {
        self.delegate = delegate
        self.currentTime = currentTime
    }

    func listIdentityDocuments(
        consumerSessionClientSecret: String,
        consumerPublishableKey: String
    ) -> Promise<NetworkedIdentityDocumentListResponse> {
        let now = currentTime()
        let expiration = now + Self.secondsUntilExpiration
        return Promise(
            value: NetworkedIdentityDocumentListResponse(
                data: [
                    seededDocument(name: "passport", type: .passport, created: now, expiration: expiration),
                    seededDocument(name: "driving_license", type: .drivingLicense, created: now, expiration: expiration),
                ]
            )
        )
    }

    func createAssociationToken(
        identityDocumentID: String,
        consumerSessionClientSecret: String,
        consumerPublishableKey: String
    ) -> Promise<NetworkedIdentityAssociationTokenResponse> {
        guard identityDocumentID.hasPrefix(Self.seededIDPrefix) else {
            return delegate.createAssociationToken(
                identityDocumentID: identityDocumentID,
                consumerSessionClientSecret: consumerSessionClientSecret,
                consumerPublishableKey: consumerPublishableKey
            )
        }
        return Promise(value: NetworkedIdentityAssociationTokenResponse(associationToken: Self.seededTokenPrefix + identityDocumentID))
    }

    func createSaveAssociationToken(
        verificationSessionID: String,
        consumerSessionClientSecret: String,
        consumerPublishableKey: String
    ) -> Promise<NetworkedIdentityAssociationTokenResponse> {
        // The save endpoints aren't deployed yet; a sample token lets the playground show the save flow.
        Promise(value: NetworkedIdentityAssociationTokenResponse(associationToken: Self.seededSaveToken))
    }

    func lookupConsumer(
        emailAddress: String,
        verificationSessionClientSecrets: [String]?
    ) -> Promise<NetworkedIdentityLookupResponse> {
        delegate.lookupConsumer(
            emailAddress: emailAddress,
            verificationSessionClientSecrets: verificationSessionClientSecrets
        )
    }

    func signUp(request: NetworkedIdentitySignUpRequest) -> Promise<NetworkedIdentitySignUpResponse> {
        delegate.signUp(request: request)
    }

    func startVerification(
        request: NetworkedIdentityStartVerificationRequest,
        consumerPublishableKey: String
    ) -> Promise<NetworkedIdentityConsumerSessionResponse> {
        delegate.startVerification(request: request, consumerPublishableKey: consumerPublishableKey)
    }

    func confirmVerification(
        request: NetworkedIdentityConfirmVerificationRequest,
        consumerPublishableKey: String
    ) -> Promise<NetworkedIdentityConsumerSessionResponse> {
        delegate.confirmVerification(request: request, consumerPublishableKey: consumerPublishableKey)
    }

    func logOut(
        consumerSessionClientSecret: String,
        verificationSessionClientSecrets: [String]?,
        consumerPublishableKey: String
    ) -> Promise<NetworkedIdentityConsumerSessionResponse> {
        delegate.logOut(
            consumerSessionClientSecret: consumerSessionClientSecret,
            verificationSessionClientSecrets: verificationSessionClientSecrets,
            consumerPublishableKey: consumerPublishableKey
        )
    }

    func extendSession(
        consumerSessionClientSecret: String,
        consumerPublishableKey: String
    ) -> Promise<NetworkedIdentityExtendSessionResponse> {
        delegate.extendSession(
            consumerSessionClientSecret: consumerSessionClientSecret,
            consumerPublishableKey: consumerPublishableKey
        )
    }

    private func seededDocument(
        name: String,
        type: NetworkedIdentityDocumentType,
        created: Int,
        expiration: Int
    ) -> NetworkedIdentityDocument {
        NetworkedIdentityDocument(
            id: Self.seededIDPrefix + name,
            documentType: type,
            created: created,
            country: "US",
            region: nil,
            redactedDocumentNumber: "••••1234",
            expirationDate: expiration,
            liveCaptured: true
        )
    }
}

/// Debug-only: sample attachments satisfy document capture locally. Other fields still use the
/// test backend; final submission is simulated because the sample files do not exist there.
final class SeededDocumentsIdentityAPIClient: IdentityAPIClient {
    private let delegate: IdentityAPIClient
    private var allowsSeededDocuments = false
    private var hasSeededDocument = false
    private var latestData: StripeAPI.VerificationPageData?

    init(delegate: IdentityAPIClient) {
        self.delegate = delegate
    }

    var verificationSessionId: String { delegate.verificationSessionId }
    var supportsNetworkedIdentity: Bool { delegate.supportsNetworkedIdentity }

    func getIdentityVerificationPage() -> Promise<StripeAPI.VerificationPage> {
        let promise = Promise<StripeAPI.VerificationPage>()
        delegate.getIdentityVerificationPage().observe { [self] result in
            if case .success(let page) = result {
                allowsSeededDocuments = !page.livemode
                hasSeededDocument = false
                latestData = .init(
                    id: page.id, requirements: .init(errors: [], missing: page.requirements.missing),
                    status: page.status, submitted: page.submitted, closed: false
                )
            }
            promise.fullfill(with: result)
        }
        return promise
    }

    func updateIdentityVerificationPageData(
        updating verificationData: StripeAPI.VerificationPageDataUpdate
    ) -> Promise<StripeAPI.VerificationPageData> {
        remember(delegate.updateIdentityVerificationPageData(updating: verificationData))
    }

    func submitIdentityVerificationPage() -> Promise<StripeAPI.VerificationPageData> {
        guard hasSeededDocument, let latestData else {
            return remember(delegate.submitIdentityVerificationPage())
        }
        let data = applyingSeededDocument(to: latestData)
        guard data.requirements.errors.isEmpty, data.requirements.missing.isEmpty,
              data.status == .requiresInput, !data.closed else {
            return Promise(value: data)
        }
        let completed = StripeAPI.VerificationPageData(
            id: verificationSessionId, requirements: data.requirements,
            status: .processing, submitted: true, closed: true
        )
        self.latestData = completed
        return Promise(value: completed)
    }

    func attachNetworkedIdentityDocument(associationToken: String) -> Promise<StripeAPI.VerificationPageData> {
        guard associationToken.hasPrefix(SeededDocumentsNetworkedIdentityAPIClient.seededTokenPrefix) else {
            hasSeededDocument = false
            return remember(delegate.attachNetworkedIdentityDocument(associationToken: associationToken))
        }
        guard allowsSeededDocuments, let latestData,
              latestData.status == .requiresInput, !latestData.closed,
              latestData.requirements.errors.isEmpty else {
            return Promise(error: SeededDocumentError.unavailable)
        }
        hasSeededDocument = true
        return Promise(value: applyingSeededDocument(to: latestData))
    }

    /// A sample save token records nothing on the backend: the session is returned unchanged, so the save flow
    /// can be shown in any mode without claiming a verification result.
    func prepareNetworkedIdentityDocumentSave(associationToken: String) -> Promise<StripeAPI.VerificationPageData> {
        guard associationToken == SeededDocumentsNetworkedIdentityAPIClient.seededSaveToken else {
            return remember(delegate.prepareNetworkedIdentityDocumentSave(associationToken: associationToken))
        }
        return Promise(value: latestData.map(applyingSeededDocument(to:)) ?? .init(
            id: verificationSessionId, requirements: .init(errors: [], missing: []),
            status: .processing, submitted: true, closed: true
        ))
    }

    func skipNetworkedIdentity() -> Promise<StripeAPI.VerificationPageData> {
        guard allowsSeededDocuments, let latestData else {
            return remember(delegate.skipNetworkedIdentity())
        }
        hasSeededDocument = false
        return Promise(value: latestData)
    }

    func uploadImage(
        _ image: UIImage, compressionQuality: CGFloat, purpose: String, fileName: String
    ) -> Future<STPAPIClient.FileAndUploadMetrics> {
        delegate.uploadImage(image, compressionQuality: compressionQuality, purpose: purpose, fileName: fileName)
    }

    func verifyTestVerificationSession(simulateDelay: Bool) -> Promise<StripeAPI.VerificationPageData> {
        remember(delegate.verifyTestVerificationSession(simulateDelay: simulateDelay))
    }

    func unverifyTestVerificationSession(simulateDelay: Bool) -> Promise<StripeAPI.VerificationPageData> {
        remember(delegate.unverifyTestVerificationSession(simulateDelay: simulateDelay))
    }

    func generatePhoneOtp() -> Promise<StripeAPI.VerificationPageData> {
        remember(delegate.generatePhoneOtp())
    }

    func cannotPhoneVerifyOtp() -> Promise<StripeAPI.VerificationPageData> {
        remember(delegate.cannotPhoneVerifyOtp())
    }

    private func remember(_ request: Promise<StripeAPI.VerificationPageData>) -> Promise<StripeAPI.VerificationPageData> {
        let promise = Promise<StripeAPI.VerificationPageData>()
        request.observe { [self] result in
            promise.fullfill(with: result.map { data in
                latestData = data
                return applyingSeededDocument(to: data)
            })
        }
        return promise
    }

    private func applyingSeededDocument(to data: StripeAPI.VerificationPageData) -> StripeAPI.VerificationPageData {
        guard hasSeededDocument else { return data }
        return .init(
            id: data.id,
            requirements: .init(
                errors: data.requirements.errors,
                missing: data.requirements.missing.subtracting([.idDocumentFront, .idDocumentBack])
            ),
            status: data.status, submitted: data.submitted, closed: data.closed
        )
    }

    private enum SeededDocumentError: Error {
        case unavailable
    }
}
