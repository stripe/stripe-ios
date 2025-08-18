//
//  LinkAppearance.swift
//  StripePaymentSheet
//
//  Created by Michael Liberatore on 7/14/25.
//

import UIKit

// Customizable appearance-related configuration for Stripe-provided Link UI.
@_spi(STP)
public struct LinkAppearance {

    /// Configuration values for the primary button.
    public struct PrimaryButtonConfiguration {

        /// The corner radius of of the primary button.
        public let cornerRadius: CGFloat

        /// The height of the primary button.
        public let height: CGFloat

        /// Creates a new instance of `PrimaryButtonConfiguration`.
        /// - Parameters:
        ///   - cornerRadius: The corner radius of of the primary button
        ///   - height: The height of the primary button.
        public init(cornerRadius: CGFloat, height: CGFloat) {
            self.cornerRadius = cornerRadius
            self.height = height
        }
    }

    /// Custom colors used throughout the Link UI. Defaults to Link colors.
    public struct Colors {
        /// The primary color used in the Link UI. Defaults to the Link brand color.
        public let primary: UIColor?

        /// The border color used for selected elements, such as text fields.
        public let selectedBorder: UIColor?

        /// Creates a new instance of `Colors`.
        /// - Parameters:
        ///   - primary: The primary color used in the Link UI. Defaults to the Link brand color.
        ///   - selectedBorder: The border color used for selected elements, such as text fields.
        public init(primary: UIColor?, selectedBorder: UIColor?) {
            self.primary = primary
            self.selectedBorder = selectedBorder
        }
    }

    /// Custom colors used throughout the Link UI. Defaults to Link colors.
    public let colors: Colors?

    /// Configuration values for the primary button. Uses reasonable defaults if nothing is provided.
    public let primaryButton: PrimaryButtonConfiguration?

    /// Style options for colors in the Link UI.
    public let style: PaymentSheet.UserInterfaceStyle

    /// When true, reduces Link branding in payment method previews by showing payment
    /// method-specific icons (e.g., Visa, Mastercard) instead of the Link icon.
    public let reduceLinkBranding: Bool

    /// Creates a new instance of `LinkAppearance`.
    /// - Parameters:
    ///   - colors: Custom colors used throughout the Link UI. Defaults to Link colors.
    ///   - primaryButton: Configuration values for the primary button. Uses reasonable defaults if nothing is provided.
    ///   - style: Style options for colors in the Link UI.
    ///   - reduceLinkBranding: When true, reduces Link branding by showing payment method-specific icons. Defaults to false.
    public init(
        colors: Colors? = nil,
        primaryButton: PrimaryButtonConfiguration? = nil,
        style: PaymentSheet.UserInterfaceStyle = .automatic,
        reduceLinkBranding: Bool = false
    ) {
        self.colors = colors
        self.primaryButton = primaryButton
        self.style = style
        self.reduceLinkBranding = reduceLinkBranding
    }
}
