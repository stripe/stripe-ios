//
//  VerifyDocumentViaWalletManager.swift
//  StripeIdentity
//
//  Created by Stripe on 6/3/26.
//

import Foundation
import PassKit
@_spi(STP) import StripeCore

protocol VerifyDocumentViaWalletManagerProtocol: AnyObject {
    func isVerifyDocumentViaWalletAvailable() async -> Bool
    @MainActor func requestDocument() async throws -> StripeAPI.VerificationPageWalletIdentitySessionSubmission.Status
}

enum VerifyDocumentViaWalletManagerError: Error {
    case unavailable
    case invalidNonce
    case invalidEncryptedResponse
    case missingDocument
    case unsupportedRequestedElements
}

@_spi(VerifyWithWallet) public final class VerifyDocumentViaWalletManager: VerifyDocumentViaWalletManagerProtocol {
    // TODO: remove once the API returns this
    public static var shouldEnableVerifyDocumentViaWallet: Bool = false
    private static let localMerchantIdentifier = "merchant.com.stripe.IdentityVerification-Example"

    private var shouldEnableVerifyDocumentViaWallet: Bool
    private var idDocumentTypeAllowlistKeys: [String]
    private let apiClient: IdentityAPIClient?
    private var activeAuthorizationController: AnyObject?

    init(
        shouldEnableVerifyDocumentViaWallet: Bool?,
        idDocumentTypeAllowlistKeys: [String],
        apiClient: IdentityAPIClient?
    ) {
        self.shouldEnableVerifyDocumentViaWallet =
            VerifyDocumentViaWalletManager.shouldEnableVerifyDocumentViaWallet
            || (shouldEnableVerifyDocumentViaWallet ?? false)
        self.idDocumentTypeAllowlistKeys = idDocumentTypeAllowlistKeys
        self.apiClient = apiClient
    }

    public convenience init(idDocumentTypeAllowlistKeys: [String]) {
        self.init(
            shouldEnableVerifyDocumentViaWallet: true,
            idDocumentTypeAllowlistKeys: idDocumentTypeAllowlistKeys,
            apiClient: nil
        )
    }

    func isVerifyDocumentViaWalletAvailable() async -> Bool {
        guard shouldEnableVerifyDocumentViaWallet else {
            return false
        }

        guard #available(iOS 16.0, *) else {
            return false
        }

        return await !requestableDocumentDescriptors().isEmpty
    }

    @MainActor
    func requestDocument() async throws -> StripeAPI.VerificationPageWalletIdentitySessionSubmission.Status {
        guard shouldEnableVerifyDocumentViaWallet else {
            throw VerifyDocumentViaWalletManagerError.unavailable
        }

        guard #available(iOS 16.0, *) else {
            throw VerifyDocumentViaWalletManagerError.unavailable
        }

        let walletSession = try await createWalletIdentitySession()
        guard let nonce = walletSession.request.nonce.base64URLDecodedData else {
            throw VerifyDocumentViaWalletManagerError.invalidNonce
        }

        guard let descriptor = try await makeRequestableDocumentDescriptor(
            documentRequests: walletSession.request.documentRequests
        ) else {
            return try await submitWalletIdentitySession(
                id: walletSession.sessionId,
                outcome: .noDocument
            ).status
        }

        let request = PKIdentityRequest()
        request.descriptor = descriptor
        request.nonce = nonce
        request.merchantIdentifier = walletSession.request.merchantIdentifier

        let outcome = try await requestDocumentOutcome(request)

        return try await submitWalletIdentitySession(
            id: walletSession.sessionId,
            outcome: outcome
        ).status
    }

    @MainActor
    public func requestLocalDocumentData() async throws -> (
        nonce: Data,
        merchantIdentifier: String,
        encryptedData: Data
    ) {
        guard #available(iOS 16.0, *),
            let descriptor = await requestableDocumentDescriptors().first
        else {
            throw VerifyDocumentViaWalletManagerError.unavailable
        }

        let nonce = Data((0..<32).map { _ in UInt8.random(in: .min ... .max) })
        let request = PKIdentityRequest()
        request.descriptor = descriptor
        request.nonce = nonce
        request.merchantIdentifier = Self.localMerchantIdentifier

        guard let document = try await requestDocument(request) else {
            throw VerifyDocumentViaWalletManagerError.missingDocument
        }
        return (nonce, Self.localMerchantIdentifier, document.encryptedData)
    }

    @MainActor
    @available(iOS 16.0, *)
    private func requestDocumentOutcome(
        _ request: PKIdentityRequest
    ) async throws -> StripeAPI.VerificationPageWalletIdentitySessionOutcome {
        do {
            guard let document = try await requestDocument(request) else {
                return .noDocument
            }
            guard !document.encryptedData.isEmpty else {
                throw VerifyDocumentViaWalletManagerError.invalidEncryptedResponse
            }
            return .credentialReturned(
                encryptedResponse: document.encryptedData.base64URLEncodedString
            )
        } catch {
            guard let nonCredentialOutcome = Self.nonCredentialOutcome(for: error) else {
                throw error
            }
            return nonCredentialOutcome
        }
    }

    @available(iOS 16.0, *)
    static func nonCredentialOutcome(
        for error: Error
    ) -> StripeAPI.VerificationPageWalletIdentitySessionOutcome? {
        let error = error as NSError
        guard error.domain == PKIdentityErrorDomain,
            let code = PKIdentityError.Code(rawValue: error.code)
        else {
            return nil
        }
        if #available(iOS 18.0, *), code == .regionNotSupported {
            return .noDocument
        }

        switch code {
        case .cancelled:
            return .userDeclined
        case .notSupported:
            return .noDocument
        default:
            return nil
        }
    }

    @available(iOS 16.0, *)
    private func makeRequestableDocumentDescriptor(
        documentRequests: [StripeAPI.VerificationPageWalletIdentitySession.Request.DocumentRequest]
    ) async throws -> (any PKIdentityDocumentDescriptor)? {
        let descriptors = await requestableDocumentDescriptors(
            in: try makeDocumentDescriptors(documentRequests: documentRequests)
        )
        guard !descriptors.isEmpty else {
            return nil
        }

        if descriptors.count == 1 {
            return descriptors[0]
        }

        if #available(iOS 26.0, *) {
            return PKIdentityAnyOfDescriptor(descriptors: descriptors)
        }

        return descriptors[0]
    }

    @available(iOS 16.0, *)
    private func requestableDocumentDescriptors(
        in descriptors: [any PKIdentityDocumentDescriptor]
    ) async -> [any PKIdentityDocumentDescriptor] {
        let authorizationController = PKIdentityAuthorizationController()
        var requestableDescriptors: [any PKIdentityDocumentDescriptor] = []
        for descriptor in descriptors {
            if await authorizationController.canRequestDocument(descriptor) {
                requestableDescriptors.append(descriptor)
            }
        }

        return requestableDescriptors
    }

    @available(iOS 16.0, *)
    private func requestableDocumentDescriptors() async -> [any PKIdentityDocumentDescriptor] {
        return await requestableDocumentDescriptors(in: makeDocumentDescriptorsForAvailability())
    }

    @available(iOS 16.0, *)
    private func makeDocumentDescriptors(
        documentRequests: [StripeAPI.VerificationPageWalletIdentitySession.Request.DocumentRequest]
    ) throws -> [any PKIdentityDocumentDescriptor] {
        var descriptors: [any PKIdentityDocumentDescriptor] = []
        for request in documentRequests where idDocumentTypeAllowlistKeys.contains(request.documentType) {
            let descriptor: (any PKIdentityDocumentDescriptor)?
            switch request.documentType {
            case "driving_license":
                descriptor = PKIdentityDriversLicenseDescriptor()
            case "id_card":
                if #available(iOS 18.0, *) {
                    descriptor = PKIdentityNationalIDCardDescriptor()
                } else {
                    descriptor = nil
                }
            case "passport":
                if #available(iOS 26.0, *) {
                    descriptor = PKIdentityPhotoIDDescriptor()
                } else {
                    descriptor = nil
                }
            default:
                descriptor = nil
            }
            if let descriptor {
                addElements(try identityElements(from: request.requestedElements), to: descriptor)
                descriptors.append(descriptor)
            }
        }

        return descriptors
    }

    @available(iOS 16.0, *)
    private func makeDocumentDescriptorsForAvailability() -> [any PKIdentityDocumentDescriptor] {
        let requests = idDocumentTypeAllowlistKeys.map {
            StripeAPI.VerificationPageWalletIdentitySession.Request.DocumentRequest(
                documentType: $0,
                requestedElements: defaultRequestedElements
            )
        }
        return (try? makeDocumentDescriptors(documentRequests: requests)) ?? []
    }

    @available(iOS 16.0, *)
    private func addElements(_ identityElements: [PKIdentityElement], to descriptor: any PKIdentityDocumentDescriptor) {
        descriptor.addElements(
            identityElements,
            intentToStore: .mayStore
        )
    }

    @available(iOS 16.0, *)
    private func identityElements(from requestedElements: [String]) throws -> [PKIdentityElement] {
        guard !requestedElements.isEmpty else {
            throw VerifyDocumentViaWalletManagerError.unsupportedRequestedElements
        }

        var elements: [PKIdentityElement] = []
        for requestedElement in requestedElements {
            if let identityElement = identityElement(for: requestedElement) {
                elements.append(identityElement)
            } else {
                throw VerifyDocumentViaWalletManagerError.unsupportedRequestedElements
            }
        }
        guard !elements.isEmpty else {
            throw VerifyDocumentViaWalletManagerError.unsupportedRequestedElements
        }
        return elements
    }

    @available(iOS 16.0, *)
    private func identityElement(for identifier: String) -> PKIdentityElement? {
        switch identifier {
        case "org.iso.18013.5.1.given_name",
             "org.iso.23220.photoid.1.given_name_unicode":
            return .givenName
        case "org.iso.18013.5.1.family_name",
             "org.iso.23220.photoid.1.family_name_unicode":
            return .familyName
        case "org.iso.18013.5.1.birth_date",
             "org.iso.23220.photoid.1.birth_date":
            return .dateOfBirth
        case "org.iso.18013.5.1.document_number",
             "org.iso.23220.photoid.1.document_number":
            return .documentNumber
        case "org.iso.18013.5.1.issue_date",
             "org.iso.23220.photoid.1.issue_date":
            return .documentIssueDate
        case "org.iso.18013.5.1.expiry_date",
             "org.iso.23220.photoid.1.expiry_date":
            return .documentExpirationDate
        case "org.iso.18013.5.1.issuing_authority",
             "org.iso.23220.photoid.1.issuing_authority":
            return .issuingAuthority
        case "org.iso.18013.5.1.portrait",
             "org.iso.23220.photoid.1.portrait":
            return .portrait
        case "org.iso.18013.5.1.address",
             "org.iso.23220.photoid.1.address":
            return .address
        default:
            return nil
        }
    }

    private var defaultRequestedElements: [String] {
        return [
            "org.iso.18013.5.1.given_name",
            "org.iso.18013.5.1.family_name",
            "org.iso.18013.5.1.portrait",
            "org.iso.18013.5.1.address",
            "org.iso.18013.5.1.birth_date",
            "org.iso.18013.5.1.document_number",
            "org.iso.18013.5.1.issue_date",
            "org.iso.18013.5.1.expiry_date",
            "org.iso.18013.5.1.issuing_authority",
        ]
    }

    private func createWalletIdentitySession() async throws -> StripeAPI.VerificationPageWalletIdentitySession {
        guard let apiClient else {
            throw VerifyDocumentViaWalletManagerError.unavailable
        }
        return try await withCheckedThrowingContinuation { continuation in
            apiClient.createWalletIdentitySession().observe { result in
                continuation.resume(with: result)
            }
        }
    }

    private func submitWalletIdentitySession(
        id: String,
        outcome: StripeAPI.VerificationPageWalletIdentitySessionOutcome
    ) async throws -> StripeAPI.VerificationPageWalletIdentitySessionSubmission {
        guard let apiClient else {
            throw VerifyDocumentViaWalletManagerError.unavailable
        }
        return try await withCheckedThrowingContinuation { continuation in
            apiClient.submitWalletIdentitySession(id: id, outcome: outcome).observe { result in
                continuation.resume(with: result)
            }
        }
    }

    @MainActor
    @available(iOS 16.0, *)
    private func requestDocument(_ request: PKIdentityRequest) async throws -> PKIdentityDocument? {
        let authorizationController = PKIdentityAuthorizationController()
        activeAuthorizationController = authorizationController
        defer {
            activeAuthorizationController = nil
        }

        return try await withCheckedThrowingContinuation { continuation in
            authorizationController.requestDocument(request) { document, error in
                if let document {
                    continuation.resume(returning: document)
                } else if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }
    }
}
