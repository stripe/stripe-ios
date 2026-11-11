//
//  LinkRequestSurface.swift
//  StripePaymentSheet
//
//  Created by Mat Schmid on 8/9/25.
//

import Foundation
@_spi(STP) import StripePayments

@_spi(STP) public enum LinkRequestSurface: String {
    /// Used for requests from the `StripePaymentSheet` SDK.
    case paymentElement = "ios_payment_element"
    /// Used for requests from the `StripeCryptoOnramp` SDK.
    case cryptoOnramp = "ios_crypto_onramp"
    /// Used for requests from the `StripeIdentity` SDK.
    case identityProduct = "ios_identity_product"
    /// Used for requests from the standalone `LinkController` API.
    case standaloneLink = "ios_link_standalone"
}

@_spi(STP) public extension LinkRequestSurface {
    static let `default`: LinkRequestSurface = .paymentElement
}

extension LinkRequestSurface {
    /// Identity offers native Link to merchants that haven't set up app attestation; merchants that have keep attesting.
    /// This relies on Link limiting the session keys it issues for the Identity surface to Identity's own use, so a key
    /// read out of the app can't act on the rest of the account.
    /// #TODO - Networked Identity [NI-Contract]: Link's backend doesn't limit these keys yet.
    func skipsAttestation(for elementsSession: STPElementsSession) -> Bool {
        self == .identityProduct && elementsSession.linkSettings?.useAttestationEndpoints != true
    }
}
