//
//  LinkConfiguration.swift
//  StripePaymentSheet
//
//  Created by Mat Schmid on 8/15/25.
//

import Foundation

/// Injectible configuration for Link behavior and content.
@_spi(STP) @_spi(LinkControllerPreview)
public struct LinkConfiguration {

    /// Custom hint message to display in the wallet view. If `nil`, no hint will be shown.
    @_spi(STP) public let hintMessage: String?

    /// Whether to allow the user to log out. When `false`, the logout menu button will be hidden.
    @_spi(STP) public let allowLogout: Bool

    /// The payment method types to support in the Link sheet. If `nil`, all available types are shown.
    @_spi(LinkControllerPreview) public let supportedPaymentMethodTypes: [LinkPaymentMethodType]?

    /// The merchant name displayed in Link UI (e.g. consent text, wallet header).
    /// If `nil`, defaults to the host app's `CFBundleDisplayName` / `CFBundleName`.
    @_spi(LinkControllerPreview) public let merchantDisplayName: String?

    /// Creates a new instance of `LinkConfiguration`.
    /// - Parameters:
    ///   - hintMessage: Custom hint message to display in the wallet view. If `nil`, no hint will be shown.
    ///   - allowLogout: Whether to allow the user to log out. When `false`, the logout menu button will be hidden. Defaults to `true`.
    @_spi(STP) public init(
        hintMessage: String? = nil,
        allowLogout: Bool = true
    ) {
        self.hintMessage = hintMessage
        self.allowLogout = allowLogout
        self.supportedPaymentMethodTypes = nil
        self.merchantDisplayName = nil
    }

    /// Creates a new instance of `LinkConfiguration`.
    /// - Parameters:
    ///   - supportedPaymentMethodTypes: The payment method types to support in the Link sheet. If `nil`, all available types are shown.
    ///   - merchantDisplayName: The merchant name displayed in Link UI. If `nil`, defaults to the app's `CFBundleDisplayName`.
    @_spi(LinkControllerPreview) public init(
        supportedPaymentMethodTypes: [LinkPaymentMethodType]? = nil,
        merchantDisplayName: String? = nil
    ) {
        self.hintMessage = nil
        self.allowLogout = true
        self.supportedPaymentMethodTypes = supportedPaymentMethodTypes
        self.merchantDisplayName = merchantDisplayName
    }
}
