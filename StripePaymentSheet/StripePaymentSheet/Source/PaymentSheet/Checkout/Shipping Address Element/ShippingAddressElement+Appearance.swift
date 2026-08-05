//
//  ShippingAddressElement+Appearance.swift
//  StripePaymentSheet
//
//  Created by George Birch on 8/4/26.

@_spi(STP) import StripeUICore
import UIKit

@_spi(STP)
@_spi(ReactNativeSDK)
extension ShippingAddressElement {
    /// Appearance configuration for ``ShippingAddressElement``.
    public struct Appearance: Equatable {
        /// Describes the appearance of fonts in the shipping address form.
        public var font: Font = .init()

        /// Describes the colors in the shipping address form.
        public var colors: Colors = .init()

        /// Describes the appearance of the primary button.
        public var primaryButton: PrimaryButton = .init()

        /// The corner radius used for inputs and, by default, the primary button.
        /// If `nil`, the platform default is used.
        public var cornerRadius: CGFloat? = PaymentSheet.Appearance.defaultCornerRadius

        /// The border width used for inputs and divider lines.
        public var borderWidth: CGFloat = PaymentSheet.Appearance.defaultBorderWidth

        /// The shadow used for address inputs and, by default, the primary button.
        public var shadow: Shadow = .init()

        /// The insets between the content and edges of address inputs.
        public var textFieldInsets: NSDirectionalEdgeInsets = PaymentSheet.Appearance.defaultTextFieldInsets

        /// The insets around the shipping address form and primary button.
        public var formInsets: NSDirectionalEdgeInsets = PaymentSheet.Appearance.defaultFormInsets

        /// Creates an appearance with default values.
        public init() {}

        /// Describes the appearance of fonts in the shipping address form.
        public struct Font: Equatable {
            /// The scale factor for all generated font sizes in the shipping address form.
            /// Must be greater than zero. Default is `1`.
            public var sizeScaleFactor: CGFloat = 1 {
                didSet {
                    if sizeScaleFactor <= 0 {
                        assertionFailure("sizeScaleFactor must be a value greater than zero")
                        sizeScaleFactor = 1
                    }
                }
            }

            /// The font family used throughout the shipping address form.
            /// The font's size and weight are ignored.
            public var base: UIFont = .systemFont(ofSize: UIFont.labelFontSize)

            /// Custom font configuration for specific text styles.
            public var custom: Custom = .init()

            /// Creates a font appearance with default values.
            public init() {}

            /// Describes custom fonts for specific text styles.
            public struct Custom: Equatable {
                /// The font used for the title of the shipping address form.
                /// If `nil`, a bold font derived from ``Font/base`` and ``Font/sizeScaleFactor`` is used.
                /// ``Font/sizeScaleFactor`` does not affect this font.
                public var headline: UIFont?

                /// Creates a custom font appearance with default values.
                public init() {}
            }
        }

        /// Describes the colors in the shipping address form.
        public struct Colors: Equatable {
            /// The accent color used for interactive controls.
            public var primary: UIColor = .systemBlue

            /// The background color of the shipping address form.
            public var background: UIColor = .systemBackground

            /// The background color of address inputs.
            public var componentBackground: UIColor = .dynamic(
                light: .systemBackground,
                dark: .secondarySystemBackground
            )

            /// The border color of address inputs.
            public var componentBorder: UIColor = .systemGray3

            /// The color of divider lines between address inputs.
            public var componentDivider: UIColor = .systemGray3

            /// The color used for primary text.
            public var text: UIColor = .label

            /// The color used for secondary text.
            public var textSecondary: UIColor = .secondaryLabel

            /// The text color of address inputs.
            public var componentText: UIColor = .label

            /// The color of placeholder text in address inputs.
            public var componentPlaceholderText: UIColor = .secondaryLabel

            /// The color used for navigation icons.
            public var icon: UIColor = .secondaryLabel

            /// The color used for errors and destructive actions.
            public var danger: UIColor = .systemRed

            /// Creates a color appearance with default values.
            public init() {}
        }

        /// Appearance configuration for a shadow.
        public struct Shadow: Equatable {
            /// The shadow color.
            public var color: UIColor = .black

            /// The shadow opacity.
            public var opacity: CGFloat = 0.05

            /// The shadow offset.
            public var offset: CGSize = .init(width: 0, height: 2)

            /// The shadow blur radius.
            public var radius: CGFloat = 4

            /// Creates a shadow appearance with default values.
            public init() {}
        }

        /// Appearance configuration for the primary button.
        public struct PrimaryButton: Equatable {
            /// The background color of the primary button.
            /// If `nil`, ``Appearance/colors`` ``Colors/primary`` is used.
            public var backgroundColor: UIColor?

            /// The text color of the primary button.
            /// If `nil`, a contrasting color is derived from the background color.
            public var textColor: UIColor?

            /// The background color of the primary button when disabled.
            /// If `nil`, the enabled background color is used.
            public var disabledBackgroundColor: UIColor?

            /// The text color of the primary button when disabled.
            /// If `nil`, the enabled text color is used with reduced opacity.
            public var disabledTextColor: UIColor?

            /// The corner radius of the primary button.
            /// If `nil`, ``Appearance/cornerRadius`` is used.
            public var cornerRadius: CGFloat?

            /// The border color of the primary button.
            public var borderColor: UIColor = .quaternaryLabel

            /// The border width of the primary button.
            public var borderWidth: CGFloat = PaymentSheet.Appearance.defaultBorderWidth

            /// The font of the primary button.
            /// If `nil`, a font derived from ``Appearance/font`` is used.
            /// ``Font/sizeScaleFactor`` does not affect this font.
            public var font: UIFont?

            /// The shadow of the primary button.
            /// If `nil`, ``Appearance/shadow`` is used.
            public var shadow: Shadow?

            /// The height of the primary button. Default is `44`.
            public var height: CGFloat = 44 {
                didSet {
                    if height <= 0 {
                        assertionFailure("height must be a value greater than zero")
                        height = 44
                    }
                }
            }

            /// Creates a primary button appearance with default values.
            public init() {}
        }
    }
}
