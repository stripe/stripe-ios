//
//  PaymentSheetTestUtils.swift
//  StripeiOS Tests
//
//  Created by Yuki Tokuhiro on 6/16/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

@_spi(STP) @testable import Stripe
@_spi(STP) @testable import StripeCore
@_spi(STP) @testable import StripeUICore

class PaymentSheetTestUtils {
    // Copy and pasted from PaymentSheetSnapshotTests
    static var snapshotTestTheme: PaymentSheet.Appearance {
        var appearance = PaymentSheet.Appearance()

        // Customize the font
        var font = PaymentSheet.Appearance.Font()
        font.sizeScaleFactor = 0.85
        font.base = UIFont(name: "AvenirNext-Regular", size: 12)!
        

        appearance.cornerRadius = 0.0
        appearance.borderWidth = 2.0
        appearance.shadow = PaymentSheet.Appearance.Shadow(color: .orange,
                                                           opacity: 0.5,
                                                          offset: CGSize(width: 0, height: 2),
                                                                     radius: 4)

        // Customize the colors
        var colors = PaymentSheet.Appearance.Colors()
        colors.primary = .systemOrange
        colors.background = .cyan
        colors.componentBackground = .yellow
        colors.componentBorder = .systemRed
        colors.componentDivider = .black
        colors.text = .red
        colors.textSecondary = .orange
        colors.componentText = .red
        colors.componentPlaceholderText = .systemBlue
        colors.icon = .green
        colors.danger = .purple

        appearance.font = font
        appearance.colors = colors
        
        return appearance
    }
}
