//
//  NetworkedIdentityLinkSession.swift
//  StripeIdentity
//

import UIKit

/// Consumer credentials Identity needs for Networked Identity calls made outside of Link.
struct NetworkedIdentityConsumerCredentials: Equatable {
    let linkSessionKey: String
}

struct NetworkedIdentityLinkAccount: Equatable {
    let email: String
    let isVerified: Bool
    /// Nil until Link has a session key.
    let credentials: NetworkedIdentityConsumerCredentials?
}

/// Link login and session for Networked Identity. Link owns lookup, one-time codes, sign-up, the
/// session secrets and their refresh; Identity only reads the Link session key it needs.
@MainActor
protocol NetworkedIdentityLinkSession: AnyObject {
    /// Must succeed before any other call.
    func configure(merchantPublishableKey: String) async throws

    /// Presents Link's own sign-in and sign-up screens, including code verification, until the session is
    /// verified. `phoneNumber` only prefills sign-up. Returns nil when the user dismisses Link.
    func authenticateWithLinkUI(
        email: String?,
        phoneNumber: String?,
        mode: NetworkedIdentityMode,
        from viewController: UIViewController
    ) async throws -> NetworkedIdentityLinkAccount?
}
