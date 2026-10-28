//
//  NetworkedIdentityState.swift
//  StripeIdentity
//

import Foundation

/// The user-visible phases of Networked Identity. Credentials never enter this state.
enum NetworkedIdentityState: Equatable {
    /// No attempt in progress; the Link sheet is hidden.
    case idle
    /// Configuring Link or restoring a handed-in session; Identity's sheet is hidden meanwhile.
    case preparing
    case documentsPending
    case selectDocument(documents: [NetworkedIdentityDocument], selectedDocumentID: String?)
    case sharingDocument(NetworkedIdentityDocument)
    case documentShared(NetworkedIdentityDocument)
    case savePending
    case savePrepared
    /// Saving failed; the sheet stays open to say so, since there's no capture to fall back to.
    case saveFailed(details: String?)
    case fullCaptureFallback
    case cancelled
    /// Link's own screens handle sign-in and sign-up; Identity's sheet is hidden meanwhile.
    case linkAuthentication

    /// Whether Identity's Link sheet shows this state.
    var presentsIdentitySheet: Bool {
        switch self {
        case .preparing, .linkAuthentication:
            return false
        default:
            return isInProgress
        }
    }

    /// Whether an attempt is in progress; it may be on Link's screens rather than Identity's sheet.
    var isInProgress: Bool {
        switch self {
        case .idle, .fullCaptureFallback, .cancelled:
            return false
        default:
            return true
        }
    }
}

enum NetworkedIdentityMode: Equatable {
    /// Returning user: share a saved ID, started from the intro.
    case reuse
    /// Save this verification's ID to Link, offered once nothing else is missing, before submitting.
    case save
}

/// How an attempt ended, for the Identity flow to act on.
enum NetworkedIdentityOutcome: Equatable {
    case documentShared
    case savePrepared
    case manualCapture
    case fallback
    case cancelled
}
