//
//  Checkout+CurrencySelectorViewAppearance.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 4/6/26.
//

import UIKit

@_spi(STP)
@_spi(ReactNativeSDK)
extension Checkout.CurrencySelectorView {
    /// Appearance configuration for ``Checkout.CurrencySelectorView``.
    public struct Appearance {

        // MARK: - Dimensions

        /// Height of the selector track. Default is `32`.
        public var height: CGFloat = 32.0

        /// Corner radius applied to the track and the selected currency pill. Default is `16` (capsule).
        public var cornerRadius: CGFloat = 16.0

        /// Border width for the track and pill outlines. Default is `0`.
        public var borderWidth: CGFloat = 0

        // MARK: - Colors

        /// Border color for the track and pill. Default is `.separator`.
        public var border: UIColor = .separator

        /// Background color of the selector track. Default is `.tertiarySystemFill`.
        public var background: UIColor = .tertiarySystemFill

        /// Background color of the selected currency pill. Default is white in light mode and `.tertiaryLabel` in dark mode.
        public var selectedBackground: UIColor = UIColor { traits in
            traits.userInterfaceStyle == .dark ? .tertiaryLabel : .white
        }

        // MARK: - Typography

        /// The base font used throughout the selector. Weights are derived automatically.
        /// Default is `.systemFont(ofSize: 14, weight: .medium)`.
        public var font: UIFont = .systemFont(ofSize: 14, weight: .medium)

        /// Multiplier applied to all font sizes. For example, `1.2` makes text 20% larger.
        /// Must be greater than 0. Default is `1.0`.
        public var sizeScaleFactor: CGFloat = 1.0 {
            didSet {
                if sizeScaleFactor <= 0.0 {
                    assertionFailure("sizeScaleFactor must be a value greater than zero")
                    sizeScaleFactor = 1.0
                }
            }
        }

        // MARK: - Text Colors

        /// Text color used for primary content. Default is `.label`.
        public var text: UIColor = .label

        /// Text color for the currently selected currency option. Default is `.label`.
        public var selectedText: UIColor = .label

        /// Text color for caption text. Default is `.secondaryLabel`.
        /// Alpha values below 0.5 are clamped to 0.5 to keep regulatory text legible.
        public var textSecondary: UIColor = .secondaryLabel {
            didSet {
                // Re-assignment in didSet is safe for value types (no recursion).
                if textSecondary.cgColor.alpha < 0.5 {
                    textSecondary = textSecondary.withAlphaComponent(0.5)
                }
            }
        }

        /// Color for error messages shown below the selector. Default is `.systemRed`.
        public var danger: UIColor = .systemRed

        // MARK: - Content

        /// Controls what content is displayed in each currency option's label.
        public enum LabelContent {
            /// Displays only the currency code (e.g. "USD").
            case currencyCode
            /// Displays the formatted amount (e.g. "$12.00").
            case amount
        }

        /// Controls what is displayed in each currency option's label. Default is `.currencyCode`.
        public var labelContent: LabelContent = .currencyCode

        /// Creates an appearance with default values.
        public init() {}

    }
}
