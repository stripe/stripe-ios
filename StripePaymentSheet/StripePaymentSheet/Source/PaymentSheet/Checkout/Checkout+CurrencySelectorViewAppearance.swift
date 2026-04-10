//
//  Checkout+CurrencySelectorViewAppearance.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 4/6/26.
//

import UIKit

@_spi(CheckoutSessionsPreview)
extension Checkout.CurrencySelectorView {
    /// Appearance configuration for ``Checkout.CurrencySelectorView``.
    public struct Appearance {
        /// Corner radius of the currency selector container.
        /// Default: `8.0`
        public var cornerRadius: CGFloat = 8.0

        /// Font for the currency option labels (e.g., "🇬🇧 £12.99").
        /// Default: `.systemFont(ofSize: 14, weight: .medium)`
        public var titleFont: UIFont = .systemFont(ofSize: 14, weight: .medium)

        /// Font for the exchange rate disclosure text below the selector.
        /// Default: `.systemFont(ofSize: 12, weight: .regular)`
        public var subtitleFont: UIFont = .systemFont(ofSize: 12, weight: .regular)

        /// Background color of the selector track.
        /// Default: `.secondarySystemBackground`
        public var backgroundColor: UIColor = .secondarySystemBackground

        /// Background color of the selected currency pill.
        /// Default: `.systemBackground`
        public var selectedColor: UIColor = .systemBackground

        /// Text color for the selected currency option.
        /// Default: `.label`
        public var selectedTextColor: UIColor = .label

        /// Text color for the unselected currency option.
        /// Default: `.secondaryLabel`
        public var unselectedTextColor: UIColor = .secondaryLabel

        /// Border color for the track and pill.
        /// Default: `.separator`
        public var borderColor: UIColor = .separator

        /// Text color for the exchange rate disclosure caption.
        /// Default: `.secondaryLabel`
        public var captionColor: UIColor = .secondaryLabel

        /// Color for error messages displayed below the selector.
        /// Default: `.systemRed`
        public var dangerColor: UIColor = .systemRed

        /// Creates an appearance with default values.
        public init() {}

        /// Bridges this appearance to a `PaymentSheet.Appearance` for internal
        /// `TwoOptionSelectorView` reuse.
        func asPaymentSheetAppearance() -> PaymentSheet.Appearance {
            var ps = PaymentSheet.Appearance()
            ps.cornerRadius = cornerRadius
            ps.colors.background = backgroundColor
            ps.colors.componentBackground = selectedColor
            ps.colors.componentText = selectedTextColor
            ps.colors.textSecondary = unselectedTextColor
            ps.colors.componentBorder = borderColor
            ps.colors.danger = dangerColor
            ps.font.base = titleFont
            return ps
        }
    }
}
