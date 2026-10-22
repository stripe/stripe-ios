//
//  NetworkedIdentityConfig.swift
//  StripeIdentity
//

import Foundation
@_spi(STP) import StripeCore

/// What the Networked Identity flow needs from the VerificationPage, with the host's debug options applied.
struct NetworkedIdentityConfig: Equatable {
    let route: NetworkedIdentityRoute
    let saveEnabled: Bool
    /// The backend found a saved document for the provided email.
    let savedDocumentAvailable: Bool
    let merchantPublishableKey: String?
    let merchantEmail: String?
    /// Prefills Link sign-up only; never used to look up or select a Link account.
    let phoneNumberAutofillHint: String?
    let seedSavedDocuments: Bool

    static func from(
        page: StripeAPI.VerificationPage,
        options: IdentityVerificationSheet.Configuration.NetworkedIdentityOptions?
    ) -> NetworkedIdentityConfig {
        let debugRoute: NetworkedIdentityRoute?
        switch options?.debugRoute {
        case "reuse": debugRoute = .reuse
        case "save": debugRoute = .save
        case "none": debugRoute = NetworkedIdentityRoute.none
        default: debugRoute = nil
        }
        return NetworkedIdentityConfig(
            route: debugRoute ?? page.networkedIdentityRoute,
            saveEnabled: debugRoute.map { $0 == .reuse || $0 == .save }
                ?? (page.networkedIdentity?.saveEnabled == true),
            // The debug reuse route stands for a page that found a saved document.
            savedDocumentAvailable: debugRoute.map { $0 == .reuse }
                ?? (page.networkedIdentity?.reuseAvailable == true),
            // The debug options win so the PoC can run before the backend returns these fields.
            merchantPublishableKey: options?.debugMerchantPublishableKey ?? page.merchantPublishableKey,
            merchantEmail: options?.debugProvidedEmail ?? page.networkedIdentity?.lookupEmail,
            phoneNumberAutofillHint: page.networkedIdentity?.phoneNumberAutofillHint,
            // #TODO - Networked Identity [NI-Contract]: test-mode Link accounts with saved documents.
            seedSavedDocuments: options?.debugSeedSavedDocuments ?? false
        )
    }
}
