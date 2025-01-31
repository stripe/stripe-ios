//
//  ElementsSessionContext+Extensions.swift
//  StripePaymentSheet
//
//  Created by Mat Schmid on 2025-01-30.
//

@_spi(STP) import StripeCore

extension ElementsSessionContext.StyleConfig {
    /// Convenience init to transform a `PaymentSheet.UserInterfaceStyle` into `ElementsSessionContext.StyleConfig`.
    init(from style: PaymentSheet.UserInterfaceStyle) {
        switch style {
        case .automatic: self = .automatic
        case .alwaysLight: self = .alwaysLight
        case .alwaysDark: self = .alwaysDark
        }
    }
}
