//
//  ShadowedRoundedRectangleView.swift
//  StripeiOS
//
//  Created by Yuki Tokuhiro on 1/28/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import UIKit
@_spi(STP) import StripeUICore

/// The shadowed rounded rectangle that our cells use to display content
/// For internal SDK use only
@objc(STP_Internal_ShadowedRoundedRectangle)
class ShadowedRoundedRectangle: UIView {
    let roundedRectangle: UIView
    let appearance: PaymentSheet.Appearance
    lazy var shouldDisplayShadow: Bool = true {
        didSet {
            if shouldDisplayShadow {
                layer.applyShadowAppearance(shape: appearance.shape)
            } else {
                layer.shadowOpacity = 0
            }
        }
    }

    var isEnabled: Bool = true {
        didSet {
            updateBackgroundColor()
        }
    }

    private func updateBackgroundColor() {
        if isEnabled {
            roundedRectangle.backgroundColor = appearance.color.componentBackground
        } else {
            roundedRectangle.backgroundColor = InputFormColors.disabledBackgroundColor
        }
    }

    required init(appearance: PaymentSheet.Appearance) {
        self.appearance = appearance
        roundedRectangle = UIView()
        roundedRectangle.layer.cornerRadius = appearance.shape.cornerRadius
        roundedRectangle.layer.masksToBounds = true

        super.init(frame: .zero)

        layer.cornerRadius = appearance.shape.cornerRadius
        layer.applyShadowAppearance(shape: appearance.shape)

        addSubview(roundedRectangle)
        updateBackgroundColor()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // Update shadow paths based on current frame
        roundedRectangle.frame = bounds

        // Turn off shadows in dark mode
        if #available(iOS 12.0, *) {
            if traitCollection.userInterfaceStyle == .dark || !shouldDisplayShadow {
                layer.shadowOpacity = 0
            } else {
                layer.applyShadowAppearance(shape: appearance.shape)
            }
        }

        // Update shadow (cg)color
        layer.applyShadowAppearance(shape: appearance.shape)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        setNeedsLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
