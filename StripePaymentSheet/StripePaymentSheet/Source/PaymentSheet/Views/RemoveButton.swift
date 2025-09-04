//
//
//  RemoveButton.swift
//  StripePaymentSheet
//
// Created by George Birch on 9/4/2025.
// Copyright © 2025 Stripe, Inc. All rights reserved.
//

import Foundation
import PassKit
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripePaymentsUI
@_spi(STP) import StripeUICore
import UIKit

/// Remove button
/// For internal SDK use only
@objc(STP_Internal_RemoveButton)
class RemoveButton: UIView {
    private let appearance: PaymentSheet.Appearance
    private let backgroundMaskView: UIView
    private let button: UIButton

    override var intrinsicContentSize: CGSize {
        return CGSize(
            width: UIView.noIntrinsicMetric,
            height: appearance.primaryButton.height
        )
    }

    init(
        title: String = .Localized.remove,
        appearance: PaymentSheet.Appearance = PaymentSheet.Appearance.default
    ) {
        self.appearance = appearance
        self.backgroundMaskView = UIView(frame: .zero)
        self.button = UIButton(frame: .zero)
        super.init(frame: .zero)

        setupButton(title: title)
        setupLayout()
        setupBackgroundColors()
    }

    private func setupButton(title: String) {
        button.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16)

        let font = appearance.primaryButton.font ?? appearance.scaledFont(for: appearance.font.base.medium, style: .callout, maximumPointSize: 25)
        if LiquidGlassDetector.isEnabled, #available(iOS 15.0, *) { // iOS 15 available check is redundnat but makes compiler happy 🤠
            var config = UIButton.Configuration.plain()
            config.titleAlignment = .center
            config.attributedTitle = AttributedString(title, attributes: AttributeContainer([.font: font, .foregroundColor: appearance.colors.danger]))
            button.configuration = config
        } else if #available(iOS 15.0, *) {
            var config = UIButton.Configuration.bordered()
            config.baseBackgroundColor = .clear
            config.background.cornerRadius = appearance.primaryButton.cornerRadius ?? appearance.cornerRadius
            config.background.strokeWidth = appearance.selectedBorderWidth ?? appearance.borderWidth * 1.5
            config.background.strokeColor = appearance.colors.danger
            config.titleAlignment = .center
            config.attributedTitle = AttributedString(title, attributes: AttributeContainer([.font: font, .foregroundColor: appearance.colors.danger]))
            button.configuration = config
        } else {
            button.setTitleColor(appearance.colors.danger, for: .normal)
            button.setTitleColor(appearance.colors.danger.disabledColor, for: .highlighted)
            button.layer.borderColor = appearance.colors.danger.cgColor
            button.layer.borderWidth = appearance.selectedBorderWidth ?? appearance.borderWidth * 1.5
            button.layer.cornerRadius = appearance.primaryButton.cornerRadius ?? appearance.cornerRadius
            button.setTitle(title, for: .normal)
            button.titleLabel?.textAlignment = .center
            button.titleLabel?.font = font
            button.titleLabel?.adjustsFontForContentSizeCategory = true
        }
        button.addTarget(self, action: #selector(buttonTouchDown(_:)), for: .touchDown)
        button.addTarget(self, action: #selector(buttonTouchUp(_:)), for: [.touchUpInside, .touchUpOutside])
    }

    private func setupLayout() {
        if LiquidGlassDetector.isEnabled {
            self.ios26_applyCapsuleCornerConfiguration()
            self.backgroundMaskView.ios26_applyCapsuleCornerConfiguration()

            addAndPinSubview(backgroundMaskView)
        }
        addAndPinSubview(button)
    }

    private func setupBackgroundColors() {
        guard LiquidGlassDetector.isEnabled else { return }

        // We create a translucent mask to place on top of the background color
        // This allows us to dynamically generate an appropriate fill color
        //    based on the Appearance API without requiring new values
        // In the future we should consider adding a new Appearance API value
        let backgroundBaseColor = UIColor.dynamic(light: appearance.colors.background, dark: appearance.colors.danger)
        let colorMaskForLight = UIColor.black.withAlphaComponent(0.08)
        let colorMaskForDark = appearance.colors.background.withAlphaComponent(0.85)
        let maskColor = UIColor.dynamic(light: colorMaskForLight, dark: colorMaskForDark)

        backgroundMaskView.backgroundColor = maskColor
        backgroundColor = backgroundBaseColor
    }

    @objc private func buttonTouchDown(_: UIButton) {
        if #available(iOS 15.0, *)  {
            button.configuration?.attributedTitle?.foregroundColor = appearance.colors.danger.disabledColor
            button.configuration?.background.strokeColor = appearance.colors.danger.disabledColor
        } else {
            button.setTitleColor(appearance.colors.danger.disabledColor, for: .normal)
            button.layer.borderColor = appearance.colors.danger.disabledColor.cgColor
        }
    }

    @objc private func buttonTouchUp(_: UIButton) {
        if #available(iOS 15.0, *)  {
            button.configuration?.attributedTitle?.foregroundColor = appearance.colors.danger
            button.configuration?.background.strokeColor = appearance.colors.danger
        } else {
            button.setTitleColor(appearance.colors.danger, for: .normal)
            button.layer.borderColor = appearance.colors.danger.cgColor
        }
    }

    func addTarget(_ target: Any?, action: Selector, for controlEvents: UIControl.Event) {
        button.addTarget(target, action: action, for: controlEvents)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

#if !os(visionOS)
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        setupBackgroundColors()
    }
#endif
}
