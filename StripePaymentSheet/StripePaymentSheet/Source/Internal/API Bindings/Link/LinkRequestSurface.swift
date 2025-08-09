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
}

@_spi(STP) public extension LinkRequestSurface {
    static let `default`: LinkRequestSurface = .paymentElement
}
