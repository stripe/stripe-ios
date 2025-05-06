//
//  LinkPaymentMethodPicker-AddButton.swift
//  StripePaymentSheet
//
//  Created by Ramon Torres on 10/20/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

extension LinkPaymentMethodPicker {

    final class AddButton: UIControl {
        struct Constants {
            static let iconSize: CGSize = .init(width: 24, height: 24)
        }

        private let lightModeIcon = Image.icon_add_bordered.makeImage(template: false)
        private let darkModeIcon = Image.icon_add_bordered_dark.makeImage(template: false)
        private let iconView = UIImageView()

        private lazy var textLabel: UILabel = {
            let label = UILabel()
            label.text = String.Localized.add_a_payment_method
            label.numberOfLines = 0
            label.textColor = tintColor
            label.font = LinkUI.font(forTextStyle: .bodyEmphasized)
            label.adjustsFontForContentSizeCategory = true
            return label
        }()

        override var isHighlighted: Bool {
            didSet {
                update()
            }
        }

        init() {
            super.init(frame: .zero)

            isAccessibilityElement = true
            accessibilityTraits = .button
            accessibilityLabel = textLabel.text
            directionalLayoutMargins = Cell.Constants.margins

            setupUI()
            update()
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
            if self.point(inside: point, with: event) {
                return self
            }

            return nil
        }

        override func tintColorDidChange() {
            super.tintColorDidChange()
            self.textLabel.textColor = tintColor
        }

        private func setupUI() {
            setIcon()

            let stackView = UIStackView(arrangedSubviews: [iconView, textLabel])
            stackView.spacing = Cell.Constants.contentSpacing
            stackView.alignment = .center
            stackView.translatesAutoresizingMaskIntoConstraints = false

            addSubview(stackView)

            NSLayoutConstraint.activate([
                iconView.widthAnchor.constraint(equalToConstant: Constants.iconSize.width),
                iconView.heightAnchor.constraint(equalToConstant: Constants.iconSize.height),
                stackView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
                stackView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor),
                stackView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
                stackView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
            ])
        }

        private func update() {
            if isHighlighted {
                iconView.alpha = 0.7
                textLabel.alpha = 0.7
                backgroundColor = .linkControlHighlight
            } else {
                iconView.alpha = 1
                textLabel.alpha = 1
                backgroundColor = .clear
            }
        }

        private func setIcon() {
            switch traitCollection.userInterfaceStyle {
            case .dark:
                iconView.image = darkModeIcon
            case .light, .unspecified:
                iconView.image = lightModeIcon
            @unknown default:
                iconView.image = lightModeIcon
            }
        }

        // UIImages need to be manually updated when the system theme changes.
        #if !os(visionOS)
        override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
            super.traitCollectionDidChange(previousTraitCollection)
            guard traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else {
                return
            }
            setIcon()
        }
        #endif
    }

}
