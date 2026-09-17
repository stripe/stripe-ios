//
//  NetworkedIdentityState.swift
//  StripeIdentity
//

import Foundation
@_spi(STP) import StripeCore

/// The user-visible phases of Networked Identity. Credentials never enter this state.
enum NetworkedIdentityState: Equatable {
    /// No attempt in progress; the Link sheet is hidden.
    case idle
    /// Configuring Link or restoring a handed-in session.
    case preparing
    case collectEmail
    case lookupPending
    /// Save only: the email has no Link account yet, so a phone number is needed to sign up.
    case collectPhone(email: String, error: String? = nil)
    case signUpPending(email: String)
    case otpStartPending
    case awaitingOTP(invalidCode: Bool)
    case otpConfirmPending
    case reauthenticationRequired
    case documentsPending
    case selectDocument(documents: [NetworkedIdentityDocument], selectedDocumentID: String?)
    case sharingDocument(NetworkedIdentityDocument)
    case documentShared(NetworkedIdentityDocument)
    case savePending
    case saved
    /// Saving failed; the sheet stays open to say so, since there's no capture to fall back to.
    case saveFailed(details: String?)
    case fullCaptureFallback(NetworkedIdentityFallbackReason)
    case cancelled

    /// Whether an attempt is in progress, so the Link sheet is shown.
    var isSheetVisible: Bool {
        switch self {
        case .idle, .fullCaptureFallback, .cancelled:
            return false
        default:
            return true
        }
    }
}

enum NetworkedIdentityFallbackReason: Equatable {
    case noLinkAccount
    case noReusableDocuments
    case userSelectedManualCapture
    case unavailable
}

enum NetworkedIdentityMode: Equatable {
    /// Returning user: share a saved ID, started from the intro.
    case reuse
    /// Save this verification's ID to Link, started from the success screen.
    case save
}

/// How an attempt ended, for the Identity flow to act on.
enum NetworkedIdentityOutcome: Equatable {
    /// `attached` is the verification after attaching, whose requirements the flow continues from.
    case documentShared(NetworkedIdentityDocument, attached: StripeAPI.VerificationPageData)
    case saved
    case fallback(NetworkedIdentityFallbackReason)
    case cancelled
}
