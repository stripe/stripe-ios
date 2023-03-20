//
//  CircularButton.swift
//  StripeiOS
//
//  Created by Cameron Sabol on 2/17/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import UIKit
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore

/// For internal SDK use only
@objc(STP_Internal_CircularButton)
class CircularButton: UIControl {
    private let radius: CGFloat = 10
    private let shadowOpacity: Float = 0.5
    private let style: Style
    var iconColor: UIColor {
        didSet {
            updateColor()
        }
    }

    private lazy var imageView = UIImageView()

    override var isEnabled: Bool {
        didSet {
            updateColor()
        }
    }

    enum Style {
        case back
        case close
        case remove
    }

    required init(style: Style, iconColor: UIColor = CompatibleColor.secondaryLabel, dangerColor: UIColor = .systemRed) {
        self.style = style
        self.iconColor = iconColor
        super.init(frame: .zero)

        backgroundColor = UIColor.dynamic(
            light: CompatibleColor.systemBackground, dark: CompatibleColor.systemGray2)
        layer.cornerRadius = radius
        layer.masksToBounds = false
        isAccessibilityElement = true
        accessibilityTraits = [.button]

        layer.shadowOffset = CGSize(width: 0, height: 1)
        layer.shadowRadius = 1.5
        layer.shadowColor = CompatibleColor.systemGray2.cgColor
        layer.shadowOpacity = shadowOpacity
        let path = UIBezierPath(
            arcCenter: CGPoint(x: radius, y: radius), radius: radius,
            startAngle: 0,
            endAngle: CGFloat.pi * 2,
            clockwise: true)
        layer.shadowPath = path.cgPath

        addSubview(imageView)
        switch style {
        case .back:
            imageView.image = Image.icon_chevron_left.makeImage(template: true)
            accessibilityLabel = String.Localized.back
            accessibilityIdentifier = "CircularButton.Back"
        case .close:
            imageView.image = Image.icon_x.makeImage(template: true)
            if style == .remove {
                imageView.tintColor = dangerColor
            }
            accessibilityLabel = String.Localized.close
            accessibilityIdentifier = "CircularButton.Close"
        case .remove:
            backgroundColor = UIColor.dynamic(
                light: CompatibleColor.systemBackground,
                dark: UIColor(red: 43.0 / 255.0, green: 43.0 / 255.0, blue: 47.0 / 255.0, alpha: 1))
            imageView.image = Image.icon_x.makeImage(template: true)
            imageView.tintColor = dangerColor
            accessibilityLabel = String.Localized.remove
            accessibilityIdentifier = "CircularButton.Remove"
        }
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(
                equalTo: centerXAnchor, constant: style == .back ? -0.5 : 0),
            imageView.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])

        updateShadow()
        updateColor()
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let newArea = bounds.insetBy(
            dx: -(PaymentSheetUI.minimumTapSize.width - bounds.width) / 2,
            dy: -(PaymentSheetUI.minimumTapSize.height - bounds.height) / 2)
        return newArea.contains(point)
    }

    func handleEvent(_ event: STPEvent) {
        switch event {
        case .shouldEnableUserInteraction:
            backgroundColor = CompatibleColor.systemGray2
        case .shouldDisableUserInteraction:
            backgroundColor = CompatibleColor.systemIndigo
        }
    }

    func updateShadow() {
        // Turn off shadows in dark mode
        if traitCollection.userInterfaceStyle == .dark {
            layer.shadowOpacity = 0
        } else {
            layer.shadowOpacity = shadowOpacity
        }
    }

    private func updateColor() {
        imageView.tintColor = isEnabled ? iconColor : CompatibleColor.tertiaryLabel
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateShadow()
        if style == .remove {
            if traitCollection.userInterfaceStyle == .dark {
                layer.borderWidth = 1
                layer.borderColor = CompatibleColor.systemGray2.withAlphaComponent(0.3).cgColor
            } else {
                layer.borderWidth = 0
                layer.borderColor = nil
            }
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: radius * 2, height: radius * 2)
    }
}
