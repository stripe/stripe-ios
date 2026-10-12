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

    static var captionFont: UIFont {
        UIFontMetrics(forTextStyle: .footnote).scaledFont(
            for: .systemFont(ofSize: 13, weight: .regular)
        )
    }

    static var bodyEmphasizedFont: UIFont {
        UIFontMetrics(forTextStyle: .body).scaledFont(
            for: .systemFont(ofSize: 16, weight: .semibold)
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
}
