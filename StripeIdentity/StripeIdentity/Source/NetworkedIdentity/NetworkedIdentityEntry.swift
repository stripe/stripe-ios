//
//  NetworkedIdentityEntry.swift
//  StripeIdentity
//

import Foundation

/// What the Identity screens offer, driven by the VerificationPage: the route decides whether reuse and saving are
/// offered, and a saved document the backend found adds the "Saved ID" chip.
struct NetworkedIdentityEntry: Equatable {
    let offersReuse: Bool
    let offersSave: Bool
    /// The "Saved ID" chip's email: the handed-in session's, or the provided one. Nil without a found document.
    let savedIDEmail: String?
    /// The save is recorded, so submitting saves the ID.
    let saveRecorded: Bool

    init(
        config: NetworkedIdentityConfig,
        handoff: IdentityVerificationSheet.Configuration.LinkSessionHandoff?,
        route: NetworkedIdentityRoute? = nil
    ) {
        let route = route ?? config.route
        offersReuse = route == .reuse
        offersSave = config.saveEnabled && (route == .reuse || route == .save)
        let email = handoff?.email ?? config.merchantEmail
        savedIDEmail = offersReuse && config.savedDocumentAvailable && !(email ?? "").isEmpty ? email : nil
        saveRecorded = route == .resumeSave
    }
}
