//
//  Button+Link.swift
//  StripePaymentSheet
//
//  Created by Ramon Torres on 12/1/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

@_spi(InternalOnlyAPI) import StripeUICore
import UIKit

extension Button.Configuration {

    static func linkPrimary() -> Self {
        var configuration: Button.Configuration = .primary()
        configuration.font = LinkUI.font(forTextStyle: .bodyEmphasized)
        configuration.insets = LinkUI.buttonMargins
        configuration.cornerRadius = LinkUI.cornerRadius

        // Colors
        configuration.foregroundColor = .linkContentOnButtonPrimary
        configuration.backgroundColor = .linkButtonPrimary
        configuration.disabledBackgroundColor = .linkButtonPrimary

        configuration.colorTransforms.disabledForeground = .setAlpha(amount: 0.5)
        configuration.colorTransforms.highlightedForeground = .darken(amount: 0.2)

        return configuration
    }

    static func linkPlain(foregroundColor: UIColor = .linkTextPrimary) -> Self {
        var configuration: Button.Configuration = .plain()
        configuration.font = LinkUI.font(forTextStyle: .bodyEmphasized)
        configuration.foregroundColor = foregroundColor
        configuration.disabledForegroundColor = nil
        configuration.colorTransforms.highlightedForeground = .setAlpha(amount: 0.4)
        configuration.colorTransforms.disabledForeground = .setAlpha(amount: 0.3)
        return configuration
    }
}

extension Button {

    static func linkPrimary(title: String? = nil, configuration: Configuration = .linkPrimary()) -> Button {
        let button = Button(configuration: configuration, title: title)
        LinkPrimaryButtonGradientView.attach(to: button)
        return button
    }
}

/// Renders the subtle top-to-bottom sheen (rgba(255,255,255,0.08) → 0) over Link primary buttons.
/// Inserted at index 0 so it sits above the button background but below the title.
final class LinkPrimaryButtonGradientView: UIView {
    override class var layerClass: AnyClass { CAGradientLayer.self }  // swiftlint:disable:this static_over_final_class

    static func attach(to button: UIView) {
        let gradientView = LinkPrimaryButtonGradientView()
        button.insertSubview(gradientView, at: 0)
        gradientView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            gradientView.topAnchor.constraint(equalTo: button.topAnchor),
            gradientView.leadingAnchor.constraint(equalTo: button.leadingAnchor),
            gradientView.trailingAnchor.constraint(equalTo: button.trailingAnchor),
            gradientView.bottomAnchor.constraint(equalTo: button.bottomAnchor),
        ])
    }

    private init() {
        super.init(frame: .zero)
        guard let gradientLayer = layer as? CAGradientLayer else { return }
        gradientLayer.colors = [
            UIColor(white: 1, alpha: 0.08).cgColor,
            UIColor(white: 1, alpha: 0).cgColor,
        ]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
        layer.masksToBounds = true
        isUserInteractionEnabled = false
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layoutSubviews() {
        super.layoutSubviews()
        // Match the button's corners, which can change (e.g. capsule styling).
        guard let superview else { return }
        layer.cornerRadius = superview.layer.cornerRadius
        layer.cornerCurve = superview.layer.cornerCurve
#if compiler(>=6.2)
        if #available(iOS 26.0, visionOS 26.0, *), superview.didSetCornerConfiguration {
            cornerConfiguration = superview.cornerConfiguration
        }
#endif
    }
}
