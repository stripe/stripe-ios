//
//  NetworkedIdentityConfig.swift
//  StripeIdentity
//

import Foundation
@_spi(STP) import StripeCore

/// Debug-only values for the PoC, supplied by the host app until the backend provides them.
struct NetworkedIdentityDebugOverrides: Equatable {
    let route: NetworkedIdentityRoute?
    let merchantPublishableKey: String?
    let merchantEmail: String?
    let seedSavedDocuments: Bool

    init(
        route: NetworkedIdentityRoute?,
        merchantPublishableKey: String?,
        merchantEmail: String?,
        seedSavedDocuments: Bool
    ) {
        self.route = route
        self.merchantPublishableKey = merchantPublishableKey
        self.merchantEmail = merchantEmail
        self.seedSavedDocuments = seedSavedDocuments
    }

    init(options: IdentityVerificationSheet.Configuration.NetworkedIdentityOptions) {
        let route: NetworkedIdentityRoute?
        switch options.debugRoute {
        case "reuse": route = .reuse
        case "save": route = .save
        case "none": route = NetworkedIdentityRoute.none
        default: route = nil
        }
        self.init(
            route: route,
            merchantPublishableKey: options.debugMerchantPublishableKey,
            merchantEmail: options.debugProvidedEmail,
            seedSavedDocuments: options.debugSeedSavedDocuments
        )
    }
}

/// What the Networked Identity flow needs from the VerificationPage, with the host's debug overrides applied.
struct NetworkedIdentityConfig: Equatable {
    let route: NetworkedIdentityRoute
    let merchantPublishableKey: String?
    let merchantEmail: String?
    let seedSavedDocuments: Bool

    static func from(
        page: StripeAPI.VerificationPage,
        overrides: NetworkedIdentityDebugOverrides?
    ) -> NetworkedIdentityConfig {
        NetworkedIdentityConfig(
            route: overrides?.route ?? page.networkedIdentityRoute,
            // The debug overrides win so the PoC can run before the backend returns these fields.
            merchantPublishableKey: overrides?.merchantPublishableKey ?? page.merchantPublishableKey,
            merchantEmail: overrides?.merchantEmail ?? page.networkedIdentity?.email ?? page.providedDetails?.email,
            // #TODO - Networked Identity [NI-Contract]: test-mode Link accounts with saved documents.
            seedSavedDocuments: overrides?.seedSavedDocuments ?? false
        )
    }
}
