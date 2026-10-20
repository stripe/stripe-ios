//
//  NetworkedIdentityConfig.swift
//  StripeIdentity
//

import Foundation
@_spi(STP) import StripeCore

/// What the Networked Identity flow needs from the VerificationPage and the host's options.
struct NetworkedIdentityConfig: Equatable {
    let route: NetworkedIdentityRoute
    let saveEnabled: Bool
    /// The backend found a saved document for the provided email.
    let savedDocumentAvailable: Bool
    let merchantPublishableKey: String
    let merchantEmail: String?
    /// Prefills Link sign-up only; never used to look up or select a Link account.
    let phoneNumberAutofillHint: String?

    /// Nil when the page doesn't offer Networked Identity or the host didn't opt in with a publishable key.
    static func from(
        page: StripeAPI.VerificationPage,
        options: IdentityVerificationSheet.Configuration.NetworkedIdentityOptions?
    ) -> NetworkedIdentityConfig? {
        guard let merchantPublishableKey = options?.merchantPublishableKey, !merchantPublishableKey.isEmpty,
              page.networkedIdentityRoute != .none else {
            return nil
        }
        return NetworkedIdentityConfig(
            route: page.networkedIdentityRoute,
            saveEnabled: page.networkedIdentity?.saveEnabled == true,
            savedDocumentAvailable: page.networkedIdentity?.reuseAvailable == true,
            merchantPublishableKey: merchantPublishableKey,
            merchantEmail: page.networkedIdentity?.lookupEmail,
            phoneNumberAutofillHint: page.networkedIdentity?.phoneNumberAutofillHint
        )
    }
}
