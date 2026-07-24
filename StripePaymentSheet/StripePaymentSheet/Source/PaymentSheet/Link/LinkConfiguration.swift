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
    @_spi(STP) @_spi(LinkControllerPreview) public let allowLogout: Bool

    /// The payment method types to support in the Link sheet. If `nil` or empty, all available types are shown.
    @_spi(LinkControllerPreview) public let supportedPaymentMethodTypes: [LinkPaymentMethodType]?

    /// The payment method types to use when creating the setup intent.
    /// If `nil`, the payment method types used will be chosen automatically.
    @_spi(LinkControllerPreview) public let paymentMethodTypes: [String]?

    /// The merchant name displayed in Link UI (e.g. consent text).
    /// If `nil`, defaults to the host app's `CFBundleDisplayName` / `CFBundleName`.
    @_spi(LinkControllerPreview) public let merchantDisplayName: String?

    /// Configures billing details collection in the Link sheet.
    /// If `nil`, uses the billing details collection configuration from the `PaymentElementConfiguration` passed at init.
    @_spi(LinkControllerPreview) public let billingDetailsCollectionConfiguration: PaymentSheet.BillingDetailsCollectionConfiguration?

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
        self.paymentMethodTypes = nil
        self.merchantDisplayName = nil
        self.billingDetailsCollectionConfiguration = nil
    }

    /// Creates a new instance of `LinkConfiguration`.
    /// - Parameters:
    ///   - supportedPaymentMethodTypes: The payment method types to support in the Link sheet. If `nil` or empty, all available types are shown.
    ///   - paymentMethodTypes: The payment method types to use when creating the setup intent. If `nil`, the payment method types used will be chosen automatically.
    ///   - allowLogout: Whether to allow the user to log out. When `false`, the logout menu button will be hidden. Defaults to `true`.
    ///   - merchantDisplayName: The merchant name displayed in Link UI. If `nil`, defaults to the app's `CFBundleDisplayName`.
    ///   - billingDetailsCollectionConfiguration: Configures billing details collection in the Link sheet. If `nil`, uses the billing details collection configuration from the `PaymentElementConfiguration` passed at init.
    @_spi(LinkControllerPreview) public init(
        supportedPaymentMethodTypes: [LinkPaymentMethodType]? = nil,
        paymentMethodTypes: [String]? = nil,
        allowLogout: Bool = true,
        merchantDisplayName: String? = nil,
        billingDetailsCollectionConfiguration: PaymentSheet.BillingDetailsCollectionConfiguration? = nil
    ) {
        self.hintMessage = nil
        self.allowLogout = allowLogout
        self.supportedPaymentMethodTypes = supportedPaymentMethodTypes
        self.paymentMethodTypes = paymentMethodTypes
        self.merchantDisplayName = merchantDisplayName
        self.billingDetailsCollectionConfiguration = billingDetailsCollectionConfiguration
    }
}
