//
//  PaymentSheetAppearance.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 2/22/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

@_spi(STP) import StripeUICore
import UIKit

public extension PaymentSheet {

    /// Describes the appearance of PaymentSheet
    struct Appearance: Equatable {
        /// The default appearance for PaymentSheet
        public static let `default` = Appearance()

        /// Creates a `PaymentSheet.Appearance` with default values
        public init() {}

        /// Describes the appearance of fonts in PaymentSheet
        public var font: Font = Font()

        /// Describes the colors in PaymentSheet
        public var colors: Colors = Colors()

        /// Describes the appearance of the primary button (e.g., the "Pay" button)
        public var primaryButton: PrimaryButton = PrimaryButton()

        /// The corner radius used for buttons, inputs, tabs in PaymentSheet
        /// - Note: The behavior of this property is consistent with the behavior of corner radius on `CALayer`
        public var cornerRadius: CGFloat = 6.0

        /// The border used for inputs and tabs in PaymentSheet
        /// - Note: The behavior of this property is consistent with the behavior of border width on `CALayer`
        public var borderWidth: CGFloat = 1.0

        /// The shadow used for inputs and tabs in PaymentSheet
        /// - Note: Set this to `.disabled` to disable shadows
        public var shadow: Shadow = Shadow()

        // MARK: Fonts

        /// Describes the appearance of fonts in PaymentSheet
        public struct Font: Equatable {

            /// Creates a `PaymentSheet.Appearance.Font` with default values
            public init() {}

            /// The scale factor for all font sizes in PaymentSheet. 
            /// Font sizes are multiplied by this value before being displayed. For example, setting this to 1.2 increases the size of all text by 20%. 
            /// - Note: This value must be greater than 0. The default value is 1.0.
            /// - Note: This is used in conjunction with the Dynamic Type accessibility text size.
            public var sizeScaleFactor: CGFloat = 1.0 {
                willSet {
                    if newValue <= 0.0 {
                        assertionFailure("sizeScaleFactor must be a value greater than zero")
                    }
                }
            }

            /// The font family of this font is used throughout PaymentSheet. PaymentSheet uses this font at multiple weights (e.g., regular, medium, semibold) if they exist.
            /// - Note: The size and weight of the font is ignored. To adjust font sizes, see `sizeScaleFactor`.
            public var base: UIFont = UIFont.systemFont(ofSize: UIFont.labelFontSize, weight: .regular)
        }

        // MARK: Colors

        /// Describes the colors in PaymentSheet
        public struct Colors: Equatable {

            /// Creates a `PaymentSheet.Appearance.Colors` with default values
            public init() {}

            /// The primary color used throughout PaymentSheet
            #if canImport(CompositorServices)
            public var primary: UIColor = .label
            #else
            public var primary: UIColor = .systemBlue
            #endif

            /// The color used for the background of PaymentSheet
            #if canImport(CompositorServices)
            public var background: UIColor = .clear
            #else
            public var background: UIColor = .systemBackground
            #endif

            /// The color used for the background of inputs, tabs, and other components
            public var componentBackground: UIColor = UIColor.dynamic(light: .systemBackground,
                                                      dark: .secondarySystemBackground)

            /// The border color used for inputs, tabs, and other components
            public var componentBorder: UIColor = .systemGray3

            /// The color of the divider lines used inside inputs, tabs, and other components
            public var componentDivider: UIColor = .systemGray3

            /// The default text color used in PaymentSheet, appearing over the background color
            public var text: UIColor = .label

            /// The color used for text of secondary importance. For example, this color is used for the label above input fields
            public var textSecondary: UIColor = .secondaryLabel

            /// The color of text appearing over `componentBackground`
            public var componentText: UIColor = .label

            /// The color used for input placeholder text
            public var componentPlaceholderText: UIColor = .secondaryLabel

            /// The color used for icons in PaymentSheet, such as the close or back icons
            public var icon: UIColor = .secondaryLabel

            /// The color used to indicate errors or destructive actions in PaymentSheet
            public var danger: UIColor = .systemRed
        }

        // MARK: Shadow

        /// Represents a shadow in PaymentSheet
        public struct Shadow: Equatable {

            /// A pre-configured `Shadow` in the disabled or off state
            public static var disabled: Shadow {
              return Shadow(color: .clear, opacity: 0.0, offset: .zero, radius: 0)
            }

            /// Color of the shadow
            /// - Note: The behavior of this property is consistent with `CALayer.shadowColor`
            public var color: UIColor = .black

            /// Opacity or alpha of the shadow
            /// - Note: The behavior of this property is consistent with `CALayer.shadowOpacity`
            public var opacity: CGFloat = CGFloat(0.05)

            /// Offset of the shadow
            /// - Note: The behavior of this property is consistent with `CALayer.shadowOffset`
            public var offset: CGSize = CGSize(width: 0, height: 2)

            /// Radius of the shadow
            /// - Note: The behavior of this property is consistent with `CALayer.shadowRadius`
            public var radius: CGFloat = 4

            /// Creates a `PaymentSheet.Appearance.Shadow` with default values
            public init() {}

            /// Creates a `Shadow` with the specified parameters
            /// - Parameters:
            ///   - color: Color of the shadow
            ///   - opacity: Opacity or opacity of the shadow
            ///   - offset: Offset of the shadow
            ///   - radius: Radius of the shadow
            public init(color: UIColor, opacity: CGFloat, offset: CGSize, radius: CGFloat) {
                self.color = color
                self.opacity = opacity
                self.offset = offset
                self.radius = radius
            }
        }

        // MARK: Primary Button

        /// Describes the appearance of the primary button (e.g., the "Pay" button)
        public struct PrimaryButton: Equatable {

            /// Creates a `PaymentSheet.Appearance.PrimaryButton` with default values
            public init() {}

            /// The background color of the primary button
            /// - Note: If `nil`, `appearance.colors.primary` will be used as the primary button background color
            #if canImport(CompositorServices)
            public var backgroundColor: UIColor? = .systemBlue
            #else
            public var backgroundColor: UIColor?
            #endif

            /// The text color of the primary button
            /// - Note: If `nil`, defaults to either white or black depending on the color of the button
            public var textColor: UIColor?

            /// The background color of the primary button when in a success state.
            /// - Note: Only applies to PaymentSheet. The primary button transitions to the success state when payment succeeds.
            public var successBackgroundColor: UIColor = .systemGreen

            /// The text color of the primary button when in a success state.
            /// - Note: Only applies to PaymentSheet. The primary button transitions to the success state when payment succeeds.
            /// - Note: If `nil`, defaults to `textColor`
            public var successTextColor: UIColor?

            /// The corner radius of the primary button
            /// - Note: If `nil`, `appearance.cornerRadius` will be used as the primary button corner radius
            /// - Note: The behavior of this property is consistent with the behavior of corner radius on `CALayer`
            public var cornerRadius: CGFloat?

            /// The border color of the primary button
            /// - Note: The behavior of this property is consistent with the behavior of border color on `CALayer`
            public var borderColor: UIColor = .quaternaryLabel

            /// The border width of the primary button
            /// - Note: The behavior of this property is consistent with the behavior of border width on `CALayer`
            public var borderWidth: CGFloat = 1.0

            /// The font used for the text of the primary button
            /// - Note: If `nil`, `appearance.font.base` will be used as the primary button font
            /// - Note: `appearance.font.sizeScaleFactor` does not impact the size of this font
            public var font: UIFont?

            /// The shadow of the primary button
            /// - Note: If `nil`, `appearance.shadow` will be used as the primary button shadow
            public var shadow: Shadow?
        }
    }
}
