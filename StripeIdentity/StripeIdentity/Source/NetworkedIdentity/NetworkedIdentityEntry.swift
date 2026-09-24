//
//  NetworkedIdentityEntry.swift
//  StripeIdentity
//

import Foundation

struct NetworkedIdentityEntry: Equatable {
    let reuseAvailable: Bool
    let offersSave: Bool
    /// The Link account's email: the handed-in session's, or the provided email once a lookup found it.
    let accountEmail: String?
    /// No handed-in session and no provided email: offer Link without a chip and ask for the email.
    let needsEmail: Bool

    var linkAvailable: Bool { reuseAvailable || offersSave }

    /// The intro offers reuse when there's an account to reuse, or no email to check.
    var offersReuse: Bool {
        reuseAvailable && (accountEmail != nil || needsEmail)
    }

    init(
        config: NetworkedIdentityConfig,
        handoff: IdentityVerificationSheet.Configuration.LinkSessionHandoff?,
        route: NetworkedIdentityRoute? = nil,
        accountEmail: String? = nil
    ) {
        let route = route ?? config.route
        let hasKey = !(config.merchantPublishableKey ?? "").isEmpty
        reuseAvailable = hasKey && route == .reuse
        offersSave = hasKey && (route == .resumeSave || (config.saveAvailable && (route == .reuse || route == .save)))
        self.accountEmail = accountEmail ?? handoff?.email
        needsEmail = handoff == nil && (config.merchantEmail ?? "").isEmpty
    }
}
