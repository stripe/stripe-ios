//
//  LinkConfiguration.swift
//  StripePaymentSheet
//
//  Created by Mat Schmid on 8/15/25.
//

import Foundation

/// Injectible configuration for Link behavior and content.
@_spi(STP)
public struct LinkConfiguration {

    /// Custom hint message to display in the wallet view. If `nil`, no hint will be shown.
    public let hintMessage: String?

    /// Creates a new instance of `LinkConfiguration`.
    /// - Parameters:
    ///   - hintMessage: Custom hint message to display in the wallet view. If `nil`, no hint will be shown.
    public init(hintMessage: String? = nil) {
        self.hintMessage = hintMessage
    }
}
