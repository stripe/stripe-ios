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
    @MainActor func requestDocument() async throws -> StripeAPI.VerificationPageWalletIdentitySessionOutcome
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
    private static let osVersionString = ProcessInfo.processInfo.operatingSystemVersionString

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
        VerifyWithWalletLogger.log("isVerifyDocumentViaWalletAvailable: osVersion=\(Self.osVersionString) shouldEnableVerifyDocumentViaWallet=\(shouldEnableVerifyDocumentViaWallet) idDocumentTypeAllowlistKeys=\(idDocumentTypeAllowlistKeys)")
        guard shouldEnableVerifyDocumentViaWallet else {
            VerifyWithWalletLogger.log("isVerifyDocumentViaWalletAvailable=false, shouldEnableVerifyDocumentViaWallet is false")
            return false
        }

        guard #available(iOS 16.0, *) else {
            VerifyWithWalletLogger.log("isVerifyDocumentViaWalletAvailable=false, iOS <16")
            return false
        }

        let requestable = await requestableDocumentDescriptors()
        VerifyWithWalletLogger.log("isVerifyDocumentViaWalletAvailable=\(!requestable.isEmpty), requestableDocumentDescriptors=\(requestable)")
        return !requestable.isEmpty
    }

    @MainActor
    func requestDocument() async throws -> StripeAPI.VerificationPageWalletIdentitySessionOutcome {
        VerifyWithWalletLogger.log("requestDocument: osVersion=\(Self.osVersionString) shouldEnableVerifyDocumentViaWallet=\(shouldEnableVerifyDocumentViaWallet) idDocumentTypeAllowlistKeys=\(idDocumentTypeAllowlistKeys)")
        guard shouldEnableVerifyDocumentViaWallet else {
            VerifyWithWalletLogger.logError("requestDocument: unavailable, shouldEnableVerifyDocumentViaWallet is false")
            throw VerifyDocumentViaWalletManagerError.unavailable
        }

        guard #available(iOS 16.0, *) else {
            VerifyWithWalletLogger.logError("requestDocument: unavailable, iOS <16")
            throw VerifyDocumentViaWalletManagerError.unavailable
        }

        VerifyWithWalletLogger.log("creating wallet identity session")
        let walletSession = try await createWalletIdentitySession()
        VerifyWithWalletLogger.log("created wallet identity session id=\(walletSession.sessionId) documentRequests=\(walletSession.request.documentRequests.map { $0.documentType })")
        guard let nonce = walletSession.request.nonce.base64URLDecodedData else {
            VerifyWithWalletLogger.logError("failed to decode nonce")
            throw VerifyDocumentViaWalletManagerError.invalidNonce
        }

        await logPerDescriptorCanRequestDiagnostics(documentRequests: walletSession.request.documentRequests)

        guard let descriptor = try makeSubmittableDocumentDescriptor(
            documentRequests: walletSession.request.documentRequests
        ) else {
            VerifyWithWalletLogger.logError("no document descriptor could be built for documentRequests=\(walletSession.request.documentRequests.map { $0.documentType }) with idDocumentTypeAllowlistKeys=\(idDocumentTypeAllowlistKeys); submitting noDocument without presenting PassKit UI")
            _ = try await submitWalletIdentitySession(
                id: walletSession.sessionId,
                outcome: .noDocument
            )
            return .noDocument
        }
        VerifyWithWalletLogger.log("using descriptor=\(descriptor)")

        let request = PKIdentityRequest()
        request.descriptor = descriptor
        request.nonce = nonce
        request.merchantIdentifier = walletSession.request.merchantIdentifier

        VerifyWithWalletLogger.log("requesting document from PassKit, merchantIdentifier=\(walletSession.request.merchantIdentifier)")
        let outcome = try await requestDocumentOutcome(request)
        VerifyWithWalletLogger.log("PassKit outcome=\(outcome)")

        let submission = try await submitWalletIdentitySession(
            id: walletSession.sessionId,
            outcome: outcome
        )
        VerifyWithWalletLogger.log("submitted wallet identity session, status=\(submission.status)")
        return outcome
    }

    @MainActor
    public func requestLocalDocumentData() async throws -> (
        nonce: Data,
        merchantIdentifier: String,
        encryptedData: Data
    ) {
        VerifyWithWalletLogger.log("requestLocalDocumentData: osVersion=\(Self.osVersionString) idDocumentTypeAllowlistKeys=\(idDocumentTypeAllowlistKeys)")
        guard #available(iOS 16.0, *) else {
            VerifyWithWalletLogger.logError("requestLocalDocumentData: unavailable, iOS <16")
            throw VerifyDocumentViaWalletManagerError.unavailable
        }

        let requestableDescriptors = await requestableDocumentDescriptors()
        VerifyWithWalletLogger.log("requestLocalDocumentData: requestableDocumentDescriptors=\(requestableDescriptors)")
        guard let descriptor = requestableDescriptors.first else {
            VerifyWithWalletLogger.logError("requestLocalDocumentData: no requestable descriptors")
            throw VerifyDocumentViaWalletManagerError.unavailable
        }
        VerifyWithWalletLogger.log("requestLocalDocumentData: using descriptor=\(descriptor)")

        let nonce = Data((0..<32).map { _ in UInt8.random(in: .min ... .max) })
        let request = PKIdentityRequest()
        request.descriptor = descriptor
        request.nonce = nonce
        request.merchantIdentifier = Self.localMerchantIdentifier

        guard let document = try await requestDocument(request) else {
            VerifyWithWalletLogger.logError("requestLocalDocumentData: PassKit returned no document")
            throw VerifyDocumentViaWalletManagerError.missingDocument
        }
        VerifyWithWalletLogger.log("requestLocalDocumentData: PassKit returned document with \(document.encryptedData.count) bytes")
        return (nonce, Self.localMerchantIdentifier, document.encryptedData)
    }

    @MainActor
    @available(iOS 16.0, *)
    private func requestDocumentOutcome(
        _ request: PKIdentityRequest
    ) async throws -> StripeAPI.VerificationPageWalletIdentitySessionOutcome {
        // Diagnostic-only: does NOT gate whether we call requestDocument, per the note on
        // makeSubmittableDocumentDescriptor above about canRequestDocument diverging from
        // what PassKit will actually accept.
        if let descriptor = request.descriptor {
            let canRequest = await PKIdentityAuthorizationController().canRequestDocument(descriptor)
            VerifyWithWalletLogger.log("diagnostic canRequestDocument(submittableDescriptor)=\(canRequest)")
        }
        do {
            guard let document = try await requestDocument(request) else {
                VerifyWithWalletLogger.log("PassKit returned no document")
                return .noDocument
            }
            guard !document.encryptedData.isEmpty else {
                VerifyWithWalletLogger.logError("PassKit document has empty encryptedData")
                throw VerifyDocumentViaWalletManagerError.invalidEncryptedResponse
            }
            VerifyWithWalletLogger.log("PassKit returned document with \(document.encryptedData.count) bytes")
            return .credentialReturned(
                encryptedResponse: document.encryptedData.base64URLEncodedString
            )
        } catch {
            VerifyWithWalletLogger.logError("PassKit requestDocument threw error=\(Self.describe(error))")
            guard let nonCredentialOutcome = Self.nonCredentialOutcome(for: error) else {
                VerifyWithWalletLogger.logError("error is not a recognized non-credential outcome, rethrowing")
                throw error
            }
            VerifyWithWalletLogger.log("mapped error to outcome=\(nonCredentialOutcome)")
            return nonCredentialOutcome
        }
    }

    /// Formats an error with full NSError detail (domain, raw code, mapped PKIdentityError.Code name,
    /// localizedDescription, userInfo) so a single log line has everything needed to diagnose without
    /// a follow-up device run.
    @available(iOS 16.0, *)
    private static func describe(_ error: Error) -> String {
        let nsError = error as NSError
        let mappedCode = PKIdentityError.Code(rawValue: nsError.code)
        return "domain=\(nsError.domain) code=\(nsError.code) mappedCode=\(String(describing: mappedCode)) localizedDescription=\(nsError.localizedDescription) userInfo=\(nsError.userInfo)"
    }

    @available(iOS 16.0, *)
    static func nonCredentialOutcome(
        for error: Error
    ) -> StripeAPI.VerificationPageWalletIdentitySessionOutcome? {
        let error = error as NSError
        guard error.domain == PKIdentityErrorDomain,
            let code = PKIdentityError.Code(rawValue: error.code)
        else {
            VerifyWithWalletLogger.log("nonCredentialOutcome: error domain/code not recognized as PKIdentityError, domain=\(error.domain) code=\(error.code)")
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

    /// Diagnostic-only: checks `canRequestDocument` against each individual descriptor built from the
    /// backend's `documentRequests` (with the backend's actual `requestedElements`), one type at a time,
    /// before they get combined into the `AnyOf` descriptor actually submitted. This lets us tell whether
    /// a type that's individually requestable stops being so once unioned with the others, all from a
    /// single device run's logs, without needing to rebuild/redeploy to test each type in isolation.
    @available(iOS 16.0, *)
    private func logPerDescriptorCanRequestDiagnostics(
        documentRequests: [StripeAPI.VerificationPageWalletIdentitySession.Request.DocumentRequest]
    ) async {
        guard let typedDescriptors = try? makeTypedDocumentDescriptors(documentRequests: documentRequests) else {
            VerifyWithWalletLogger.logError("diagnostic: failed to build individual descriptors for canRequestDocument checks")
            return
        }
        let authorizationController = PKIdentityAuthorizationController()
        for (documentType, descriptor) in typedDescriptors {
            let canRequest = await authorizationController.canRequestDocument(descriptor)
            VerifyWithWalletLogger.log("diagnostic canRequestDocument(documentType=\(documentType), descriptor=\(descriptor))=\(canRequest)")
        }
    }

    /// Builds the descriptor to actually submit to PassKit for a given wallet identity session,
    /// without re-checking `canRequestDocument()`. That check was already satisfied (using a generic
    /// descriptor built from `idDocumentTypeAllowlistKeys`) when we decided to show the wallet button;
    /// re-running it here against the backend's specific `requestedElements` can diverge and return
    /// false even when PassKit is able to service the request, silently skipping the PassKit UI.
    @available(iOS 16.0, *)
    private func makeSubmittableDocumentDescriptor(
        documentRequests: [StripeAPI.VerificationPageWalletIdentitySession.Request.DocumentRequest]
    ) throws -> (any PKIdentityDocumentDescriptor)? {
        return makeDocumentDescriptor(from: try makeDocumentDescriptors(documentRequests: documentRequests))
    }

    @available(iOS 16.0, *)
    private func makeDocumentDescriptor(
        from descriptors: [any PKIdentityDocumentDescriptor]
    ) -> (any PKIdentityDocumentDescriptor)? {
        guard !descriptors.isEmpty else {
            return nil
        }

        if descriptors.count == 1 {
            VerifyWithWalletLogger.log("submitting single descriptor=\(descriptors[0])")
            return descriptors[0]
        }

        if #available(iOS 26.0, *) {
            VerifyWithWalletLogger.log("combining \(descriptors.count) descriptors into PKIdentityAnyOfDescriptor: \(descriptors)")
            return PKIdentityAnyOfDescriptor(descriptors: descriptors)
        }

        VerifyWithWalletLogger.log("iOS <26, falling back to first of \(descriptors.count) descriptors=\(descriptors[0])")
        return descriptors[0]
    }

    @available(iOS 16.0, *)
    private func requestableDocumentDescriptors(
        in descriptors: [any PKIdentityDocumentDescriptor]
    ) async -> [any PKIdentityDocumentDescriptor] {
        let authorizationController = PKIdentityAuthorizationController()
        var requestableDescriptors: [any PKIdentityDocumentDescriptor] = []
        for descriptor in descriptors {
            let canRequest = await authorizationController.canRequestDocument(descriptor)
            VerifyWithWalletLogger.log("canRequestDocument(\(descriptor))=\(canRequest)")
            if canRequest {
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
    private func makeTypedDocumentDescriptors(
        documentRequests: [StripeAPI.VerificationPageWalletIdentitySession.Request.DocumentRequest]
    ) throws -> [(documentType: String, descriptor: any PKIdentityDocumentDescriptor)] {
        let disallowedRequests = documentRequests.filter { !idDocumentTypeAllowlistKeys.contains($0.documentType) }
        if !disallowedRequests.isEmpty {
            VerifyWithWalletLogger.logError("documentTypes not in idDocumentTypeAllowlistKeys=\(idDocumentTypeAllowlistKeys), skipping: \(disallowedRequests.map { $0.documentType })")
        }

        var descriptors: [(documentType: String, descriptor: any PKIdentityDocumentDescriptor)] = []
        for request in documentRequests where idDocumentTypeAllowlistKeys.contains(request.documentType) {
            VerifyWithWalletLogger.log("building descriptor for documentType=\(request.documentType) requestedElements=\(request.requestedElements)")
            let descriptor: (any PKIdentityDocumentDescriptor)?
            switch request.documentType {
            case "driving_license":
                descriptor = PKIdentityDriversLicenseDescriptor()
            case "id_card":
                // TODO(IDPROD-XXXX): re-enable once regionNotSupported investigation is resolved.
                VerifyWithWalletLogger.logError("id_card temporarily disabled for regionNotSupported debugging, skipping")
                descriptor = nil
            case "passport":
                if #available(iOS 26.0, *) {
                    descriptor = PKIdentityPhotoIDDescriptor()
                } else {
                    VerifyWithWalletLogger.logError("passport requires iOS 26+, skipping")
                    descriptor = nil
                }
            default:
                VerifyWithWalletLogger.logError("unrecognized documentType=\(request.documentType), skipping")
                descriptor = nil
            }
            if let descriptor {
                let elements = try identityElements(from: request.requestedElements)
                VerifyWithWalletLogger.log("documentType=\(request.documentType) mapped to \(elements.count) PKIdentityElements=\(elements)")
                addElements(elements, to: descriptor)
                descriptors.append((documentType: request.documentType, descriptor: descriptor))
            }
        }

        return descriptors
    }

    @available(iOS 16.0, *)
    private func makeDocumentDescriptors(
        documentRequests: [StripeAPI.VerificationPageWalletIdentitySession.Request.DocumentRequest]
    ) throws -> [any PKIdentityDocumentDescriptor] {
        return try makeTypedDocumentDescriptors(documentRequests: documentRequests).map(\.descriptor)
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
                VerifyWithWalletLogger.logError("unsupported requestedElement=\(requestedElement)")
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

        VerifyWithWalletLogger.log("calling PKIdentityAuthorizationController.requestDocument")
        return try await withCheckedThrowingContinuation { continuation in
            authorizationController.requestDocument(request) { document, error in
                VerifyWithWalletLogger.log("PKIdentityAuthorizationController.requestDocument callback, document=\(document != nil), error=\(String(describing: error))")
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
