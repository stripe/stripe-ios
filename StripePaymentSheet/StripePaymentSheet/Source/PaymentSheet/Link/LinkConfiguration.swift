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

    /// Whether to allow the user to log out. When `false`, the logout menu button will be hidden.
    public let allowLogout: Bool

    /// Creates a new instance of `LinkConfiguration`.
    /// - Parameters:
    ///   - hintMessage: Custom hint message to display in the wallet view. If `nil`, no hint will be shown.
    ///   - allowLogout: Whether to allow the user to log out. When `false`, the logout menu button will be hidden. Defaults to `true`.
    public init(hintMessage: String? = nil, allowLogout: Bool = true) {
        self.hintMessage = hintMessage
        self.allowLogout = allowLogout
    }
}
