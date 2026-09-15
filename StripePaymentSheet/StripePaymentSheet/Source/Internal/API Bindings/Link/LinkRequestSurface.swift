//
//  LinkRequestSurface.swift
//  StripePaymentSheet
//
//  Created by Mat Schmid on 8/9/25.
//

import Foundation

@_spi(STP) public enum LinkRequestSurface: String {
    /// Used for requests from the `StripePaymentSheet` SDK.
    case paymentElement = "ios_payment_element"
    /// Used for requests from the `StripeCryptoOnramp` SDK.
    case cryptoOnramp = "ios_crypto_onramp"
    /// Used for requests from the standalone `LinkController` API.
    case standaloneLink = "ios_link_standalone"
    /// Used for requests from the `StripeIdentity` SDK (Networked Identity).
    /// #TODO - Networked Identity [NI-Contract]: restore "ios_identity_product" once the backend accepts
    /// it. It is agreed but not deployed yet, and the API rejects it today.
    case identity = "web_identity_product"
}

@_spi(STP) public extension LinkRequestSurface {
    static let `default`: LinkRequestSurface = .paymentElement
}
