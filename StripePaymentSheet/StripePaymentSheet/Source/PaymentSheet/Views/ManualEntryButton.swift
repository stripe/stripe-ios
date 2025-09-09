//
//  ManualEntryButton.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 6/8/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

extension UIButton {

    static func makeManualEntryButton(appearance: PaymentSheet.Appearance) -> UIButton {
        let button = UIButton(type: .system)
        button.titleLabel?.font = appearance.scaledFont(for: appearance.font.base.regular, style: .subheadline, maximumPointSize: 20)
        button.tintColor = appearance.colors.primary

        button.setTitle(.Localized.enter_address_manually, for: .normal)
        button.titleLabel?.sizeToFit()

        if let titleLabelHeight = button.titleLabel?.frame.size.height {
            button.frame.size.height = titleLabelHeight * 2.25
        }

        button.backgroundColor = UIColor(dynamicProvider: { traitCollection in
            if traitCollection.isDarkMode {
                return appearance.colors.componentBackground
            }

            return appearance.colors.background.darken(by: 0.07)
        })

        return button
    }

    @available(iOS 26.0, *)
    static func makeManualEntryGlassButton(appearance: PaymentSheet.Appearance, didTap: @escaping () -> Void) -> UIView {
        stpAssert(LiquidGlassDetector.isEnabled)
        var manualEntryButtonAppearance = appearance
        manualEntryButtonAppearance.primaryButton.font = appearance.primaryButton.font?.regular ?? appearance.font.base.regular
        manualEntryButtonAppearance.primaryButton.textColor = UIColor(dynamicProvider: { traitCollection in
            if traitCollection.isDarkMode {
                return appearance.colors.background.contrastingColor
            }

            return appearance.colors.primary
        })
        manualEntryButtonAppearance.primaryButton.borderWidth = 0
        manualEntryButtonAppearance.primaryButton.backgroundColor = .clear
        
        let confirmButton = ConfirmButton(
            callToAction: .custom(title: .Localized.enter_address_manually),
            appearance: manualEntryButtonAppearance,
            didTap: didTap
        )
        
        // Apply glass effect using UIVisualEffectView with UIGlassEffect
        let glassEffect = UIGlassEffect(style: .regular)
        let glassView = UIVisualEffectView(effect: glassEffect)
        glassView.translatesAutoresizingMaskIntoConstraints = false
        
        // Create container view to hold both the glass effect and button
        let containerView = UIView()
        containerView.addSubview(glassView)
        containerView.addSubview(confirmButton)
        
        confirmButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            glassView.topAnchor.constraint(equalTo: containerView.topAnchor),
            glassView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            glassView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            glassView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            
            confirmButton.topAnchor.constraint(equalTo: containerView.topAnchor),
            confirmButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            confirmButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            confirmButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
        
        // Apply capsule corner radius to both views
        containerView.ios26_applyCapsuleCornerConfiguration()
        glassView.ios26_applyCapsuleCornerConfiguration()
        
        return containerView
    }
}
