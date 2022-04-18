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
    var appearance: PaymentSheet.Appearance {
        didSet {
            layer.applyShadow(theme: appearance.asElementsTheme)
            layer.cornerRadius = appearance.cornerRadius
            roundedRectangle.layer.cornerRadius = appearance.cornerRadius
            roundedRectangle.backgroundColor = appearance.colors.componentBackground
        }
    }

    lazy var shouldDisplayShadow: Bool = true {
        didSet {
            if shouldDisplayShadow {
                layer.applyShadow(theme: appearance.asElementsTheme)
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
            roundedRectangle.backgroundColor = appearance.colors.componentBackground
        } else {
            roundedRectangle.backgroundColor = appearance.colors.componentBackground.disabledColor
        }
    }

    required init(appearance: PaymentSheet.Appearance) {
        self.appearance = appearance
        roundedRectangle = UIView()
        roundedRectangle.layer.cornerRadius = appearance.cornerRadius
        roundedRectangle.layer.masksToBounds = true

        super.init(frame: .zero)

        layer.cornerRadius = appearance.cornerRadius
        layer.applyShadow(theme: appearance.asElementsTheme)

        addSubview(roundedRectangle)
        updateBackgroundColor()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // Update shadow paths based on current frame
        roundedRectangle.frame = bounds

        // Turn off shadows in dark mode
        if traitCollection.userInterfaceStyle == .dark || !shouldDisplayShadow {
            layer.shadowOpacity = 0
        } else {
            layer.applyShadow(theme: appearance.asElementsTheme)
        }

        // Update shadow (cg)color
        layer.applyShadow(theme: appearance.asElementsTheme)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        setNeedsLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
