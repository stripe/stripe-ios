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

    /// The primary color used in the Link UI. Defaults to the Link brand color.
    public let primaryColor: UIColor?

    /// Configuration values for the primary button. Uses reasonable defaults if nothing is provided.
    public let primaryButton: PrimaryButtonConfiguration?

    /// Style options for colors in the Link UI.
    public let style: PaymentSheet.UserInterfaceStyle

    /// Creates a new instance of `LinkAppearance`.
    /// - Parameters:
    ///   - primaryColor: The primary color used in the Link UI. Defaults to the Link brand color.
    ///   - primaryButton: Configuration values for the primary button. Uses reasonable defaults if nothing is provided.
    ///   - style: Style options for colors in the Link UI.
    public init(primaryColor: UIColor? = nil, primaryButton: PrimaryButtonConfiguration? = nil, style: PaymentSheet.UserInterfaceStyle = .automatic) {
        self.primaryColor = primaryColor
        self.primaryButton = primaryButton
        self.style = style
    }
}
