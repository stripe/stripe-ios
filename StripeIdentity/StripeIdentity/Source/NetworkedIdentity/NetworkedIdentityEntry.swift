//
//  NetworkedIdentityEntry.swift
//  StripeIdentity
//

import Foundation

/// What the Identity screens offer, driven by data rather than a route: a handed-in session or a lookup of
/// the provided email decides whether the intro offers reuse, and the success screen always offers saving.
struct NetworkedIdentityEntry: Equatable {
    /// A merchant publishable key is known, so Link can be offered at all.
    let linkAvailable: Bool
    /// The Link account's email: the handed-in session's, or the provided email once a lookup found it.
    var accountEmail: String?
    /// No handed-in session and no provided email: offer Link without a chip and ask for the email.
    let needsEmail: Bool

    /// The intro offers reuse when there's an account to reuse, or no email to check.
    var offersReuse: Bool {
        linkAvailable && (accountEmail != nil || needsEmail)
    }

    init(linkAvailable: Bool, accountEmail: String?, needsEmail: Bool) {
        self.linkAvailable = linkAvailable
        self.accountEmail = accountEmail
        self.needsEmail = needsEmail
    }

    init(
        config: NetworkedIdentityConfig,
        handoff: IdentityVerificationSheet.Configuration.LinkSessionHandoff?
    ) {
        self.init(
            linkAvailable: !(config.merchantPublishableKey ?? "").isEmpty,
            accountEmail: handoff?.email,
            needsEmail: handoff == nil && (config.merchantEmail ?? "").isEmpty
        )
    }
}
