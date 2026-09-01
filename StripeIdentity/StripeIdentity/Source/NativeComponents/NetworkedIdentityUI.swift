//
//  NetworkedIdentityUI.swift
//  StripeIdentity
//

@_spi(STP) import StripeUICore
import UIKit

/// Figma-derived styling that keeps Networked Identity visually aligned with Link without
/// introducing a dependency on StripePaymentSheet's internal Link UI.
enum NetworkedIdentityUI {
    static let centeredHeaderTopInset: CGFloat = 176
    static let compactHeaderTopInset: CGFloat = 48

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

    static var elementsAppearance: ElementsAppearance {
        var appearance = IdentityUI.identityElementsUITheme
        appearance.colors.primary = .label
        appearance.colors.parentBackground = .systemBackground
        appearance.colors.componentBackground = .secondarySystemBackground
        appearance.colors.disabledBackground = .secondarySystemBackground
        appearance.colors.border = .clear
        appearance.colors.divider = .clear
        appearance.colors.textFieldText = .label
        appearance.colors.bodyText = .label
        appearance.colors.secondaryText = .secondaryLabel
        appearance.colors.placeholderText = .secondaryLabel
        appearance.cornerRadius = 12
        appearance.borderWidth = 0
        appearance.shadow = nil
        appearance.textFieldInsets = .init(
            top: 12,
            leading: 16,
            bottom: 12,
            trailing: 16
        )
        return appearance
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

    static func networkedIdentityPlain() -> Self {
        var configuration: Self = .plain()
        configuration.font = NetworkedIdentityUI.bodyEmphasizedFont
        configuration.foregroundColor = .label
        configuration.insets = .init(
            top: 12,
            leading: 16,
            bottom: 12,
            trailing: 16
        )
        return configuration
    }
}
