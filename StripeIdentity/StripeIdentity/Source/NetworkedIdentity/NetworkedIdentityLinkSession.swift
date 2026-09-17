//
//  NetworkedIdentityLinkSession.swift
//  StripeIdentity
//

import Foundation

/// Consumer credentials Identity needs for Networked Identity calls made outside of Link.
struct NetworkedIdentityConsumerCredentials: Equatable {
    let publishableKey: String
    let sessionClientSecret: String
}

struct NetworkedIdentityLinkAccount: Equatable {
    let email: String
    let redactedPhoneNumber: String
    let isVerified: Bool
    /// Nil until Link has both the session secret and the consumer publishable key.
    let credentials: NetworkedIdentityConsumerCredentials?
}

/// Link login and session for Networked Identity. Link owns lookup, one-time codes, sign-up, the
/// session secrets and their refresh; Identity only reads the consumer credentials it needs.
@MainActor
protocol NetworkedIdentityLinkSession: AnyObject {
    /// Must succeed before any other call.
    func configure(merchantPublishableKey: String) async throws

    /// Restores a session handed in from outside Identity, e.g. by crypto onramp.
    func restore(credentials: NetworkedIdentityConsumerCredentials) async throws -> NetworkedIdentityLinkAccount

    /// Returns nil when the email has no Link account.
    func lookup(email: String) async throws -> NetworkedIdentityLinkAccount?

    func startVerification(isResend: Bool) async throws -> NetworkedIdentityLinkAccount

    func confirmVerification(code: String) async throws -> NetworkedIdentityLinkAccount

    func signUp(
        email: String,
        phoneNumber: String,
        country: String,
        name: String?
    ) async throws -> NetworkedIdentityLinkAccount

    func logOut() async throws
}
