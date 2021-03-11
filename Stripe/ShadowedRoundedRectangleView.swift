//
//  ShadowedRoundedRectangleView.swift
//  StripeiOS
//
//  Created by Yuki Tokuhiro on 1/28/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import UIKit

private let shadowOpacity: Float = 0.2
private let shadowRadius: CGFloat = 1.5

// The shadowed rounded rectangle that our cells use to display content
class ShadowedRoundedRectangle: UIView {
    let roundedRectangle: UIView
    let underShadowOpacity: Float = 0.5
    let underShadow: CALayer
    var shouldDisplayShadow: Bool = true {
        didSet {
            if shouldDisplayShadow {
                layer.shadowOpacity = PaymentSheetUI.defaultShadowOpacity
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
            roundedRectangle.backgroundColor = UIColor.dynamic(
                light: CompatibleColor.systemBackground,
                dark: UIColor(red: 43.0 / 255.0, green: 43.0 / 255.0, blue: 47.0 / 255.0, alpha: 1))
        } else {
            roundedRectangle.backgroundColor = STPInputFormColors.disabledBackgroundColor
        }
    }

    required init() {
        roundedRectangle = UIView()
        roundedRectangle.layer.cornerRadius = PaymentSheetUI.defaultButtonCornerRadius
        roundedRectangle.layer.masksToBounds = true

        underShadow = CALayer()
        super.init(frame: .zero)

        layer.cornerRadius = PaymentSheetUI.defaultButtonCornerRadius
        layer.shadowOffset = CGSize(width: 0, height: 1)
        layer.shadowRadius = shadowRadius
        layer.shadowColor = CompatibleColor.systemGray2.cgColor
        layer.shadowOpacity = PaymentSheetUI.defaultShadowOpacity

        underShadow.shadowOffset = CGSize(width: 0, height: 1)
        underShadow.shadowRadius = 5
        underShadow.shadowOpacity = 0.2
        layer.addSublayer(underShadow)
        addSubview(roundedRectangle)
        updateBackgroundColor()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // Update shadow paths based on current frame
        roundedRectangle.frame = bounds
        layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: 6).cgPath
        underShadow.shadowPath =
            UIBezierPath(
                roundedRect: roundedRectangle.bounds.inset(
                    by: UIEdgeInsets(top: 5, left: 5, bottom: 0, right: 5)),
                cornerRadius: PaymentSheetUI.defaultButtonCornerRadius
            ).cgPath

        // Turn off shadows in dark mode
        if #available(iOS 12.0, *) {
            if traitCollection.userInterfaceStyle == .dark || !shouldDisplayShadow {
                layer.shadowOpacity = 0
                underShadow.shadowOpacity = 0
            } else {
                layer.shadowOpacity = shadowOpacity
                underShadow.shadowOpacity = underShadowOpacity
            }
        }

        // Update shadow (cg)colors
        layer.shadowColor = CompatibleColor.systemGray2.cgColor
        underShadow.shadowColor = CompatibleColor.systemGray2.cgColor
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        setNeedsLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
