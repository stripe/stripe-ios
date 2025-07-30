//
//  Appearance.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 7/14/25.
//

import UIKit
import StripePaymentSheet

// Customizable appearance-related configuration for Stripe-provided Link UI.
@_spi(CryptoOnrampSDKPreview)
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

    /// Style options for colors in the Link UI.
    public enum Style {

        /// (default) Link will automatically switch between light and dark mode compatible colors based on device settings.
        case automatic

        /// Link will always use colors appropriate for light mode UI.
        case alwaysLight

        /// Link will always use colors appropriate for dark mode UI.
        case alwaysDark
    }

    /// The primary color used in the Link UI. Defaults to the Link brand color.
    public let primaryColor: UIColor?

    /// Configuration values for the primary button. Uses reasonable defaults if nothing is provided.
    public let primaryButton: PrimaryButtonConfiguration?

    /// Style options for colors in the Link UI.
    public let style: Style

    /// Creates a new instance of `LinkAppearance`.
    /// - Parameters:
    ///   - primaryColor: The primary color used in the Link UI. Defaults to the Link brand color.
    ///   - primaryButton: Configuration values for the primary button. Uses reasonable defaults if nothing is provided.
    ///   - style: Style options for colors in the Link UI.
    public init(primaryColor: UIColor? = nil, primaryButton: PrimaryButtonConfiguration? = nil, style: Style = .automatic) {
        self.primaryColor = primaryColor
        self.primaryButton = primaryButton
        self.style = style
    }
}

extension LinkAppearance {
    var toPaymentSheetAppearance: PaymentSheet.Appearance {
        var appearance = PaymentSheet.Appearance.defaultLinkUIAppearance
        if let primaryColor {
            appearance.colors.primary = primaryColor
            appearance.colors.brandText = primaryColor
        }

        if let primaryButton {
            appearance.primaryButton.cornerRadius = primaryButton.cornerRadius
            appearance.primaryButton.height = primaryButton.height
        }

        appearance.linkUserInterfaceStyle = style.toUserInterfaceStyle

        return appearance
    }
}

private extension LinkAppearance.Style {
    var toUserInterfaceStyle: UIUserInterfaceStyle {
        switch self {
        case .automatic:
            return .unspecified
        case .alwaysLight:
            return .light
        case .alwaysDark:
            return .dark
        }
    }
}
