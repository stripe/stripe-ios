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
    private let roundedRectangle: UIView
    private let ios26DefaultCornerStyle: CornerStyle
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

        // Corner radius
        roundedRectangle.applyCornerRadiusOrConfiguration(for: appearance, ios26DefaultCornerStyle: ios26DefaultCornerStyle)
        applyCornerRadiusOrConfiguration(for: appearance)

        // Shadow
        layer.applyShadow(shadow: appearance.asElementsTheme.shadow)
        layer.shadowPath = UIBezierPath(rect: bounds).cgPath

        // Border
        if isSelected {
            let selectedBorderWidth = appearance.selectedBorderWidth ?? appearance.borderWidth
            if selectedBorderWidth > 0 {
                layer.borderWidth = selectedBorderWidth * 1.5
            } else {
                // Without a border, the customer can't tell this is selected and it looks bad
                layer.borderWidth = 1.5
            }
            layer.borderColor = appearance.colors.selectedComponentBorder?.cgColor ?? appearance.colors.primary.cgColor
        } else {
            layer.borderWidth = appearance.borderWidth
            layer.borderColor = appearance.colors.componentBorder.cgColor
        }
    }

    required init(appearance: PaymentSheet.Appearance, ios26DefaultCornerStyle: CornerStyle = .uniform) {
        self.appearance = appearance
        self.ios26DefaultCornerStyle = ios26DefaultCornerStyle
        roundedRectangle = UIView()
        roundedRectangle.layer.masksToBounds = true
        super.init(frame: .zero)
        addAndPinSubview(roundedRectangle)
        update()
    }

    #if !os(visionOS)
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        update()
    }
    #endif

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
