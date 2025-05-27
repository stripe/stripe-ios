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

        private lazy var textLabel: UILabel = {
            let label = UILabel()
            label.text = String.Localized.add_a_payment_method
            label.numberOfLines = 0
            label.textColor = tintColor
            label.font = LinkUI.font(forTextStyle: .bodyEmphasized)
            label.adjustsFontForContentSizeCategory = true
            label.translatesAutoresizingMaskIntoConstraints = false
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
            addSubview(textLabel)

            NSLayoutConstraint.activate([
                textLabel.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
                textLabel.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor),
                textLabel.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
                textLabel.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
            ])
        }

        private func update() {
            if isHighlighted {
                textLabel.alpha = 0.7
                backgroundColor = .linkSurfaceTertiary
            } else {
                textLabel.alpha = 1
                backgroundColor = .clear
            }
        }

    }

}
