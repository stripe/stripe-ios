//
//  ShadowedRoundedRectangleView.swift
//  StripePaymentSheet
//
//  Created by Yuki Tokuhiro on 1/28/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

@_spi(STP) import StripeUICore
import UIKit

/// The shadowed rounded rectangle that our cells use to display content
class ShadowedRoundedRectangle: UIView {
    /// Our two display styles.
    /// - `floatingRounded` (default) retains original appearance-based styling (corner radius, shadow, border, etc.).
    /// - `flat` omits specific appearance-based properties (borderWidth, selectedComponentBorder, cornerRadius, shadow).
    enum Style {
        case floatingRounded
        case flat
    }

    private let roundedRectangle: UIView
    private let style: Style

    var appearance: PaymentSheet.Appearance {
        didSet {
            update()
        }
    }

    var isEnabled: Bool = true {
        didSet {
            update()
        }
    }

    var isSelected: Bool = false {
        didSet {
            update()
        }
    }

    /// All mutations to this class should route to this single method to update the UI
    private func update() {
        // Background color
        if isEnabled {
            roundedRectangle.backgroundColor = appearance.colors.componentBackground
        } else {
            roundedRectangle.backgroundColor = appearance.colors.componentBackground.disabledColor
        }

        // 2. Style-specific logic
        switch style {
        case .floatingRounded:
            // Corner radius
            roundedRectangle.layer.cornerRadius = appearance.cornerRadius
            layer.cornerRadius = appearance.cornerRadius

            // Shadow
            layer.applyShadow(shadow: appearance.asElementsTheme.shadow)
            layer.shadowPath = UIBezierPath(rect: bounds).cgPath

            // Border
            if isSelected {
                let selectedBorderWidth = appearance.selectedBorderWidth ?? appearance.borderWidth
                layer.borderWidth = selectedBorderWidth > 0 ? (selectedBorderWidth * 1.5) : 1.5
                layer.borderColor = appearance.colors.selectedComponentBorder?.cgColor
                ?? appearance.colors.primary.cgColor
            } else {
                layer.borderWidth = appearance.borderWidth
                layer.borderColor = appearance.colors.componentBorder.cgColor
            }

        case .flat:
            // Ignore (or override) the appearance-based corner radius
            roundedRectangle.layer.cornerRadius = 0
            layer.cornerRadius = 0

            // Ignore (or override) the appearance-based shadow
            layer.shadowColor = nil
            layer.shadowPath = nil

            // Minimal border — in both normal and selected states
            layer.borderWidth = 0
            layer.borderColor = UIColor.clear.cgColor
        }
    }

    required init(appearance: PaymentSheet.Appearance, style: Style = .floatingRounded) {
        self.appearance = appearance
        self.style = style
        roundedRectangle = UIView()
        roundedRectangle.layer.masksToBounds = true
        super.init(frame: .zero)
        addAndPinSubview(roundedRectangle)
        update()
    }

    #if !canImport(CompositorServices)
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        update()
    }
    #endif

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
