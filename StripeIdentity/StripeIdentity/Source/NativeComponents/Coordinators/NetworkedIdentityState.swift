//
//  NetworkedIdentityState.swift
//  StripeIdentity
//

import Foundation

/// The user-visible phases of the Networked Identity pre-capture flow.
///
/// Sensitive values intentionally live in `NetworkedIdentityCredentialStore`, not in this state.
enum NetworkedIdentityState: Equatable {
    case collectEmail
    case lookupPending
    case otpStartPending
    case awaitingOTP
    case otpConfirmPending
    case reauthenticationRequired
    case documentsPending
    case selectDocument
    case selectedDocument
    case fullCaptureFallback
    case cancelled
}

enum NetworkedIdentityFallbackReason: Equatable {
    case noLinkAccount
    case noReusableDocuments
    case userSelectedManualCapture
    case unavailable
}

enum NetworkedIdentityOTPError: Equatable {
    case invalidCode
    case verificationExpired
    case sessionExpired
    case maxAttemptsExceeded
}

/// Holds short-lived credentials in memory for the lifetime of a single flow.
@MainActor
final class NetworkedIdentityCredentialStore {
    struct ConsumerCredentials {
        let publishableKey: String
        let sessionClientSecret: String
    }

    private var consumerCredentials: ConsumerCredentials?
    private var verificationSessionClientSecrets: [String]?

    init(verificationSessionClientSecrets: [String]? = nil) {
        self.verificationSessionClientSecrets = verificationSessionClientSecrets
    }

    var hasConsumerCredentials: Bool {
        consumerCredentials != nil
    }

    var isEmpty: Bool {
        consumerCredentials == nil && verificationSessionClientSecrets == nil
    }

    func storeConsumerCredentials(
        publishableKey: String,
        sessionClientSecret: String
    ) {
        consumerCredentials = ConsumerCredentials(
            publishableKey: publishableKey,
            sessionClientSecret: sessionClientSecret
        )
    }

    func updateConsumerSessionClientSecret(_ sessionClientSecret: String) {
        guard let consumerCredentials else {
            return
        }
        self.consumerCredentials = ConsumerCredentials(
            publishableKey: consumerCredentials.publishableKey,
            sessionClientSecret: sessionClientSecret
        )
    }

    func readConsumerCredentials<T>(
        _ body: (ConsumerCredentials, [String]?) -> T
    ) -> T? {
        guard let consumerCredentials else {
            return nil
        }
        return body(consumerCredentials, verificationSessionClientSecrets)
    }

    func readVerificationSessionClientSecrets<T>(_ body: ([String]?) -> T) -> T {
        body(verificationSessionClientSecrets)
    }

    func clearConsumerCredentials() {
        consumerCredentials = nil
    }

    func clear() {
        consumerCredentials = nil
        verificationSessionClientSecrets = nil
    }
}
