//
//  NetworkedIdentityUI.swift
//  StripeIdentity
//

@_spi(STP) import StripeUICore
import UIKit

/// Link-style fonts and buttons for Networked Identity's screens. Link's own styling is internal to
/// StripePaymentSheet, so its fonts are mirrored here.
enum NetworkedIdentityUI {
    static let compactHeaderTopInset: CGFloat = 20

    static var titleFont: UIFont {
        UIFontMetrics(forTextStyle: .headline).scaledFont(
            for: .systemFont(ofSize: 24, weight: .semibold)
        )
    }

    static var bodyFont: UIFont {
        UIFontMetrics(forTextStyle: .body).scaledFont(
            for: .systemFont(ofSize: 16, weight: .regular)
        )
    }

    static var bodyEmphasizedFont: UIFont {
        UIFontMetrics(forTextStyle: .body).scaledFont(
            for: .systemFont(ofSize: 16, weight: .semibold)
        )
    }

    static var bodyMediumFont: UIFont {
        UIFontMetrics(forTextStyle: .body).scaledFont(
            for: .systemFont(ofSize: 16, weight: .medium)
        )
    }

    /// The save offer's title, in Stripe's bold rather than Link's semibold.
    static var saveTitleFont: UIFont {
        UIFontMetrics(forTextStyle: .headline).scaledFont(
            for: .systemFont(ofSize: 24, weight: .bold)
        )
    }

    /// The design's line heights, as multiples of the font size so they scale with it: 32 for titles, 24 for body.
    static let titleLineHeight: CGFloat = 32 / 24
    static let bodyLineHeight: CGFloat = 24 / 16

    // The design's colors for saving to Link: Link's palette, and Stripe's for the save offer's text and its
    // secondary button. The design is light only, so dark follows Link's dark palette and Identity's dark text color.
    static let linkPrimaryColor = UIColor.dynamic(light: rgb(0x171717), dark: .white)
    static let onLinkPrimaryColor = UIColor.dynamic(light: .white, dark: rgb(0x171717))
    static let linkSurfaceSecondaryColor = UIColor.dynamic(light: rgb(0xF5F5F5), dark: rgb(0x262626))
    static let linkTextTertiaryColor = UIColor.dynamic(light: rgb(0x707070), dark: rgb(0xA3A3A3))
    static let saveTextColor = UIColor.dynamic(light: rgb(0x353A44), dark: rgb(0xF7FAFC))
    static let saveBulletTextColor = UIColor.dynamic(light: rgb(0x30313D), dark: rgb(0xF7FAFC))
    static let secondaryButtonBorderColor = UIColor.dynamic(
        light: rgb(0xD4DEE9),
        dark: UIColor.white.withAlphaComponent(0.2)
    )
    static let secondaryButtonTextColor = UIColor.dynamic(light: rgb(0x273951), dark: rgb(0xF7FAFC))

    private static func rgb(_ hex: UInt32) -> UIColor {
        UIColor(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
}

extension UILabel {
    /// Sets `text` in lines `lineHeight` times the font's size, with the extra height split above and below the text
    /// as in the design; UIKit otherwise puts it all above. The line height is fixed here, so the label shouldn't
    /// adjust its font for later Dynamic Type changes.
    func setText(_ text: String, lineHeight: CGFloat) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.minimumLineHeight = font.pointSize * lineHeight
        paragraphStyle.maximumLineHeight = paragraphStyle.minimumLineHeight
        paragraphStyle.alignment = textAlignment
        attributedText = NSAttributedString(
            string: text,
            attributes: [
                .font: font as UIFont,
                .foregroundColor: textColor as UIColor,
                .paragraphStyle: paragraphStyle,
                .baselineOffset: (paragraphStyle.minimumLineHeight - font.lineHeight) / 2,
            ]
        )
    }
}

extension Button.Configuration {
    static func networkedIdentityPrimary() -> Self {
        var configuration: Self = .primary()
        configuration.font = NetworkedIdentityUI.bodyEmphasizedFont
        configuration.cornerRadius = 12
        configuration.foregroundColor = .systemBackground
        configuration.backgroundColor = .label
        configuration.disabledForegroundColor = .systemGray
        configuration.disabledBackgroundColor = .systemGray4
        configuration.insets = .init(
            top: 12,
            leading: 16,
            bottom: 12,
            trailing: 16
        )
        return configuration
    }

    static func networkedIdentitySecondary() -> Self {
        var configuration: Self = .secondary()
        configuration.font = NetworkedIdentityUI.bodyEmphasizedFont
        configuration.cornerRadius = 12
        configuration.foregroundColor = .label
        configuration.backgroundColor = .secondarySystemBackground
        configuration.insets = .init(
            top: 12,
            leading: 16,
            bottom: 12,
            trailing: 16
        )
        return configuration
    }

    /// The save offer's "Save with [Link logo]".
    static func networkedIdentitySave() -> Self {
        var configuration: Self = .networkedIdentityPrimary()
        configuration.cornerRadius = 6
        configuration.backgroundColor = NetworkedIdentityUI.linkPrimaryColor
        configuration.insets.top = 8
        configuration.insets.bottom = 8
        return configuration
    }

    /// The save offer's "Finish without saving".
    static func networkedIdentityOutlined() -> Self {
        var configuration: Self = .networkedIdentitySecondary()
        configuration.cornerRadius = 6
        configuration.borderWidth = 1
        configuration.borderColor = NetworkedIdentityUI.secondaryButtonBorderColor
        configuration.foregroundColor = NetworkedIdentityUI.secondaryButtonTextColor
        configuration.backgroundColor = .clear
        // A clear background can't darken when pressed.
        configuration.colorTransforms.highlightedBackground = nil
        configuration.colorTransforms.highlightedForeground = .setAlpha(amount: 0.5)
        configuration.insets.top = 8
        configuration.insets.bottom = 8
        return configuration
    }

    /// Link's pill-shaped primary button, for Done once the ID is saved.
    static func networkedIdentityDone() -> Self {
        var configuration: Self = .primary()
        configuration.font = NetworkedIdentityUI.bodyMediumFont
        configuration.cornerRadius = 28
        configuration.foregroundColor = NetworkedIdentityUI.onLinkPrimaryColor
        configuration.backgroundColor = NetworkedIdentityUI.linkPrimaryColor
        configuration.insets = .init(
            top: 16,
            leading: 16,
            bottom: 16,
            trailing: 16
        )
        return configuration
    }
}
