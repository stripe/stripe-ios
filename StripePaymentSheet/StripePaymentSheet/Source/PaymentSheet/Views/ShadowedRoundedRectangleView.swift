//
//  ShadowedRoundedRectangleView.swift
//  StripePaymentSheet
//
//  Created by Yuki Tokuhiro on 1/28/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

@_spi(STP) import StripeUICore
#if canImport(UIKit)
import UIKit
#else
import Foundation
#endif

/// The shadowed rounded rectangle that our cells use to display content
class ShadowedRoundedRectangle: UIView {
    private let roundedRectangle: UIView
    private let ios26DefaultCornerStyle: CornerStyle
    var paymentSheetAppearance: PaymentSheet.Appearance {
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
            roundedRectangle.backgroundColor = paymentSheetAppearance.colors.componentBackground
        } else {
            roundedRectangle.backgroundColor = paymentSheetAppearance.colors.componentBackground.disabledColor
        }

        // Corner radius
        roundedRectangle.applyCornerRadiusOrConfiguration(for: paymentSheetAppearance, ios26DefaultCornerStyle: ios26DefaultCornerStyle)
        applyCornerRadiusOrConfiguration(for: paymentSheetAppearance)

        // Shadow
        layer.applyShadow(shadow: paymentSheetAppearance.asElementsTheme.shadow)
        layer.shadowPath = UIBezierPath(rect: bounds).cgPath

        // Border
        if isSelected {
            let selectedBorderWidth = paymentSheetAppearance.selectedBorderWidth ?? paymentSheetAppearance.borderWidth
            if selectedBorderWidth > 0 {
                layer.borderWidth = selectedBorderWidth * 1.5
            } else {
                // Without a border, the customer can't tell this is selected and it looks bad
                layer.borderWidth = 1.5
            }
            layer.borderColor = paymentSheetAppearance.colors.selectedComponentBorder?.cgColor ?? paymentSheetAppearance.colors.primary.cgColor
        } else {
            layer.borderWidth = paymentSheetAppearance.borderWidth
            layer.borderColor = paymentSheetAppearance.colors.componentBorder.cgColor
        }
    }

    required init(appearance: PaymentSheet.Appearance, ios26DefaultCornerStyle: CornerStyle = .uniform) {
        self.paymentSheetAppearance = appearance
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
