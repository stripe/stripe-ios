//
//  LinkAppearance.swift
//  StripePaymentSheet
//
//  Created by Michael Liberatore on 7/14/25.
//

#if canImport(UIKit)
import UIKit
#else
import Foundation
#endif

// Customizable appearance-related configuration for Stripe-provided Link UI.
@_spi(CryptoOnrampAlpha)
public struct LinkAppearance {

    /// Configuration values for the primary button.
    public struct PrimaryButtonConfiguration {

        /// The corner radius of of the primary button. Defaults to Link's primary button corner radius.
        public var cornerRadius: CGFloat?

        /// The height of the primary button. Defaults to Link's primary button height.
        public var height: CGFloat?

        /// Creates a new instance of `PrimaryButtonConfiguration`.
        /// - Parameters:
        ///   - cornerRadius: The corner radius of of the primary button. Defaults to Link's primary button corner radius.
        ///   - height: The height of the primary button. Defaults to Link's primary button height.
        public init(cornerRadius: CGFloat? = nil, height: CGFloat? = nil) {
            self.cornerRadius = cornerRadius
            self.height = height
        }
    }

    /// Custom colors used throughout the Link UI. Defaults to Link colors.
    public struct Colors {
        /// The primary color used in the Link UI. Defaults to the Link brand color.
        public var primary: UIColor?

        /// The color used in the Link UI for content displayed on the primary color.
        public var contentOnPrimary: UIColor?

        /// The border color used for selected elements, such as text fields.
        public var selectedBorder: UIColor?

        /// Creates a new instance of `Colors`.
        /// - Parameters:
        ///   - primary: The primary color used in the Link UI. Defaults to the Link brand color.
        ///   - contentOnPrimary: The color used in the Link UI for content displayed on the primary color.
        ///   - selectedBorder: The border color used for selected elements, such as text fields.
        public init(primary: UIColor? = nil, contentOnPrimary: UIColor? = nil, selectedBorder: UIColor? = nil) {
            self.primary = primary
            self.contentOnPrimary = contentOnPrimary
            self.selectedBorder = selectedBorder
        }
    }

    /// Custom colors used throughout the Link UI. Defaults to Link colors.
    public var colors: Colors?

    /// Configuration values for the primary button. Uses Link defaults when individual values are not provided.
    public var primaryButton: PrimaryButtonConfiguration

    /// Style options for colors in the Link UI. Defaults to automatic.
    public var style: PaymentSheet.UserInterfaceStyle = .automatic

    /// When true, reduces Link branding in payment method previews by showing payment
    /// method-specific icons (e.g., Visa, Mastercard) instead of the Link icon.
    /// Defaults to false.
    public var reduceLinkBranding: Bool = false

    /// Creates a new instance of `LinkAppearance`.
    /// - Parameters:
    ///   - colors: Custom colors used throughout the Link UI. Defaults to Link colors.
    ///   - primaryButton: Configuration values for the primary button. Uses reasonable defaults if nothing is provided.
    ///   - style: Style options for colors in the Link UI. Defaults to automatic.
    ///   - reduceLinkBranding: When true, reduces Link branding by showing payment method-specific icons. Defaults to false.
    public init(
        colors: Colors? = nil,
        primaryButton: PrimaryButtonConfiguration? = nil,
        style: PaymentSheet.UserInterfaceStyle = .automatic,
        reduceLinkBranding: Bool = false
    ) {
        self.colors = colors
        self.primaryButton = primaryButton ?? PrimaryButtonConfiguration()
        self.style = style
        self.reduceLinkBranding = reduceLinkBranding
    }
}
