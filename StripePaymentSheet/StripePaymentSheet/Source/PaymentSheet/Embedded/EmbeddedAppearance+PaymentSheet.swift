//
//  EmbeddedAppearance+PaymentSheet.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 9/10/24.
//

import Foundation

extension EmbeddedAppearance {
    /// Creates an `PaymentSheet.Appearance` object from the current `EmbeddedAppearance`
    var paymentSheetAppearance: PaymentSheet.Appearance {
        var appearance = PaymentSheet.Appearance()
        appearance.font = font
        appearance.colors = colors
        appearance.primaryButton = primaryButton
        appearance.cornerRadius = cornerRadius
        appearance.borderWidth = borderWidth
        appearance.borderWidthSelected = borderWidthSelected
        appearance.shadow = shadow
        
        return appearance
    }
}

extension PaymentSheet.Appearance {
    
    /// Creates an `EmbeddedAppearance` object from the current `PaymentSheet.Appearance` with a `style` of `floating`
    var toFloatingEmbeddedAppearance: EmbeddedAppearance {
        var appearance = EmbeddedAppearance()
        appearance.font = font
        appearance.colors = colors
        appearance.primaryButton = primaryButton
        appearance.cornerRadius = cornerRadius
        appearance.borderWidth = borderWidth
        appearance.borderWidthSelected = borderWidthSelected
        appearance.shadow = shadow
        appearance.style = .floating
        return appearance
    }
}
