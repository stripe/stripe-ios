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
    let merchantPublishableKey: String?
    let merchantEmail: String?
    /// Prefills Link sign-up only; never used to look up or select a Link account.
    let phoneNumberAutofillHint: String?

    static func from(
        page: StripeAPI.VerificationPage,
        options: IdentityVerificationSheet.Configuration.NetworkedIdentityOptions?
    ) -> NetworkedIdentityConfig {
        NetworkedIdentityConfig(
            route: page.networkedIdentityRoute,
            saveEnabled: page.networkedIdentity?.saveEnabled == true,
            savedDocumentAvailable: page.networkedIdentity?.reuseAvailable == true,
            merchantPublishableKey: options?.merchantPublishableKey,
            merchantEmail: page.networkedIdentity?.lookupEmail,
            phoneNumberAutofillHint: page.networkedIdentity?.phoneNumberAutofillHint
        )
    }
}
