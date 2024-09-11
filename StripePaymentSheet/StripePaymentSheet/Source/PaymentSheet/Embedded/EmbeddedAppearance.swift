//
//  EmbeddedAppearance.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 9/10/24.
//

@_spi(STP) import StripeUICore
import UIKit

/// Describes the appearance of the embedded payment element
@_spi(EmbeddedPaymentMethodsViewBeta) public struct EmbeddedAppearance: Equatable {
    
    /// Describes the appearance of fonts in the embedded payment element
    public typealias Font = PaymentSheet.Appearance.Font
    
    /// Describes the colors in the embedded payment element
    public typealias Colors = PaymentSheet.Appearance.Colors
    
    /// Describes the appearance of the primary button (e.g., the "Pay" button)
    public typealias PrimaryButton = PaymentSheet.Appearance.PrimaryButton
    
    /// Describes a shadow in the embedded payment element
    public typealias Shadow = PaymentSheet.Appearance.Shadow
    
    /// The default appearance for the embedded payment element
    public static let `default` = EmbeddedAppearance()
    
    /// Creates an `EmbeddedAppearance` with default values
    public init() {}
    
    /// Describes the appearance of fonts in the embedded payment element
    public var font: Font = Font()

    /// Describes the colors in the embedded payment element
    public var colors: Colors = Colors()

    /// Describes the appearance of the primary button (e.g., the "Pay" button)
    public var primaryButton: PrimaryButton = PrimaryButton()

    /// The corner radius used for buttons, inputs, tabs in the embedded payment element
    /// - Note: The behavior of this property is consistent with the behavior of corner radius on `CALayer`
    public var cornerRadius: CGFloat = 6.0

    /// The border used for inputs and tabs in the embedded payment element
    /// - Note: The behavior of this property is consistent with the behavior of border width on `CALayer`
    public var borderWidth: CGFloat = 1.0

    /// The border width used for selected buttons and tabs in the embedded payment element
    /// - Note: If `nil`, defaults to  `borderWidth * 1.5`
    /// - Note: The behavior of this property is consistent with the behavior of border width on `CALayer`
    public var borderWidthSelected: CGFloat?

    /// The shadow used for inputs and tabs in the embedded payment element
    /// - Note: Set this to `.disabled` to disable shadows
    public var shadow: Shadow = Shadow()
    
    // MARK: Embedded row customization
    
    /// The display style options for the embedded payment element
    public enum Style {
        /// A flat style with radio buttons
        case flatRadio
        /// A floating style
        case floating
    }

    /// The display style of the embedded payment element
    public var style: Style = .flatRadio

    /// Additional vertical insets applied to a payment method row
    /// - Note: Increasing this value increases the height of the row
    public var additionalInsets: CGFloat = 4.0

    /// Appearance settings for the flat style
    public var flat: Flat = Flat()

    /// Appearance settings for the floating style
    public var floating: Floating = Floating()

    /// Describes the appearance of the flat style of the embedded payment element
    public struct Flat: Equatable {
        /// The thickness of the separator line between payment method rows
        public var separatorThickness: CGFloat = 1.0

        /// The color of the separator line between payment method rows
        /// - Note: If `nil`, defaults to `appearance.colors.componentBorder`
        public var separatorColor: UIColor?

        /// The insets of the separator line between payment method rows
        public var separatorInset: UIEdgeInsets?

        /// Determines if the top separator is visible at the top of the embedded payment element
        public var topSeparatorEnabled: Bool = true

        /// Determines if the bottom separator is visible at the bottom of the embedded payment element
        public var bottomSeparatorEnabled: Bool = true

        /// Appearance settings for the radio button
        public var radio: Radio = Radio()

        /// Describes the appearance of the radio button
        public struct Radio: Equatable {
            /// The color of the radio button when selected
            /// - Note: If `nil`, defaults to `appearance.color.primaryColor`
            public var colorSelected: UIColor?

            /// The color of the radio button when unselected
            /// - Note: If `nil`, defaults to `appearance.colors.componentBorder`
            public var colorUnselected: UIColor?
        }
    }

    /// Describes the appearance of the floating style payment method row
    public struct Floating: Equatable {
        /// The spacing between payment method rows
        public var spacing: CGFloat = 12.0
    }
}
