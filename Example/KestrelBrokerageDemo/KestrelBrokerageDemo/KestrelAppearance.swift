//
//  KestrelAppearance.swift
//  KestrelBrokerageDemo
//

@_spi(DashboardOnly) import StripeConnect
import UIKit

extension EmbeddedComponentManager.Appearance {
    /// Themes embedded components so they read as part of Kestrel rather than a web page.
    static func kestrel(surface: EmbeddedComponentSurface) -> Self {
        var appearance = Self.default
        appearance.spacingUnit = 10
        appearance.colors.background = surface == .page ? .black : .card
        appearance.colors.offsetBackground = UIColor(white: surface == .page ? 0.1 : 0.15, alpha: 1)
        appearance.colors.formBackground = UIColor(white: surface == .page ? 0.1 : 0.13, alpha: 1)
        appearance.colors.text = .white
        appearance.colors.secondaryText = UIColor(white: 0.6, alpha: 1)
        appearance.colors.border = UIColor(white: 1, alpha: 0.12)
        appearance.colors.primary = .gain
        appearance.colors.actionPrimaryText = .gain
        appearance.colors.actionSecondaryText = UIColor(white: 0.75, alpha: 1)
        appearance.colors.formHighlightBorder = .gain
        appearance.colors.formAccent = .gain
        appearance.colors.danger = .loss

        appearance.buttonPrimary.colorBackground = .gain
        appearance.buttonPrimary.colorBorder = .gain
        appearance.buttonPrimary.colorText = .black
        appearance.buttonSecondary.colorBackground = UIColor(white: 0.18, alpha: 1)
        appearance.buttonSecondary.colorBorder = UIColor(white: 0.18, alpha: 1)
        appearance.buttonSecondary.colorText = .white
        appearance.buttonDefaults.paddingVertical = 14
        appearance.buttonDefaults.labelTypography = .style(16, .semibold)

        // Badge colors must be opaque; alpha is dropped when the appearance is sent to the web view.
        appearance.badgeSuccess.colorBackground = UIColor(red: 0.04, green: 0.22, blue: 0.07, alpha: 1)
        appearance.badgeSuccess.colorText = .gain
        appearance.badgeSuccess.colorBorder = UIColor(red: 0.04, green: 0.22, blue: 0.07, alpha: 1)
        appearance.badgeNeutral.colorBackground = UIColor(white: 0.2, alpha: 1)
        appearance.badgeNeutral.colorText = UIColor(white: 0.85, alpha: 1)
        appearance.badgeNeutral.colorBorder = UIColor(white: 0.2, alpha: 1)

        appearance.cornerRadius.base = 16
        appearance.cornerRadius.form = 12
        appearance.cornerRadius.button = 26
        appearance.cornerRadius.badge = 10
        appearance.cornerRadius.overlay = 20

        appearance.typography.fontSizeBase = 16
        appearance.typography.headingLg = .style(24, .bold)
        appearance.typography.headingMd = .style(20, .bold)
        return appearance
    }
}
