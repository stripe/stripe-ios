//
//  LinkAppearance+CryptoOnramp.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 9/10/26.
//

@_spi(CryptoOnrampAlpha) import StripePaymentSheet
@_spi(STP) import StripeUICore
import SwiftUI

extension LinkAppearance {

    /// The requested SwiftUI color scheme, or nil to inherit the system appearance.
    var colorScheme: ColorScheme? {
        switch style {
        case .alwaysLight: return .light
        case .alwaysDark: return .dark
        case .automatic: return nil
        @unknown default: return nil
        }
    }

    /// The primary button background color, preserving any supplied dynamic color provider.
    var primaryButtonBackground: UIColor { colors?.primary ?? .fallbackPrimaryButtonBackground }

    /// The primary button foreground color, preserving any supplied dynamic color provider.
    var primaryButtonForeground: UIColor { colors?.contentOnPrimary ?? .fallbackPrimaryButtonForeground }
}

extension LinkAppearance.PrimaryButtonConfiguration {

    /// The configured height or the default, with a minimum 44-point touch target.
    var resolvedHeight: CGFloat { max(44, height ?? 56) }

    /// The configured corner radius or the default for the current glass availability.
    var resolvedCornerRadius: CGFloat { cornerRadius ?? (LiquidGlassDetector.isEnabledInMerchantApp ? 26 : 12) }
}

#if DEBUG
extension LinkAppearance {

    /// Standard appearance constant used in SwiftUI previews.
    static let previewLinkAppearance = LinkAppearance(
        colors: .init(
            primary: UIColor(red: 171/255.0, green: 159/255.0, blue: 242/255.0, alpha: 1),
            contentOnPrimary: UIColor(red: 29/255.0, green: 18/255.0, blue: 56/255.0, alpha: 1),
            selectedBorder: .label
        ),
        primaryButton: .init(cornerRadius: 16, height: 56),
        style: .automatic,
        reduceLinkBranding: true
    )
}
#endif
