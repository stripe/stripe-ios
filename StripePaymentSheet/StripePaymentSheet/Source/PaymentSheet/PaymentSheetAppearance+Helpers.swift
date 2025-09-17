//
//  PaymentSheetAppearance+Helpers.swift
//  StripePaymentSheet
//
//  Created by Yuki Tokuhiro on 9/15/25.
//

@_spi(STP) import StripeUICore
import UIKit

internal extension PaymentSheet.Appearance {
    var topFormInsets: NSDirectionalEdgeInsets {
        return .insets(top: formInsets.top, leading: formInsets.leading, trailing: formInsets.trailing)
    }
    static let defaultCornerRadius: CGFloat = 6
}

extension PaymentSheet.Appearance.NavigationBarStyle {
    var isGlass: Bool {
        #if !os(visionOS)
        guard #available(iOS 26.0, *) else {
            return false
        }
        return self == .glass
        #else
        return false
        #endif
    }
    var isPlain: Bool {
        return self == .plain
    }
}

extension UIView {
    /// A convenience method that looks at `appearance.cornerRadius` and applies it or, if `nil`, handles what the default value should be.
    /// - Parameter shouldUsePrimaryButtonCornerRadius: If `true`, `appearance.primaryButton.cornerRadius` (if non-nil) takes precedence over `appearance.cornerRadius`.
    func applyCornerRadiusOrConfiguration(for appearance: PaymentSheet.Appearance, ios26DefaultCornerStyle: CornerStyle = .uniform, shouldUsePrimaryButtonCornerRadius: Bool = false) {
        var appearance = appearance
        if shouldUsePrimaryButtonCornerRadius, let primaryButtonCornerRadius = appearance.primaryButton.cornerRadius {
            // Hack: `ElementsAppearance` doesn't have a primary button corner radius.
            appearance.cornerRadius = primaryButtonCornerRadius
        }
        applyCornerRadius(appearance: appearance.asElementsTheme, ios26DefaultCornerStyle: ios26DefaultCornerStyle)
    }
}
