//
//  LinkPaymentMethodPicker-Header.swift
//  StripeiOS
//
//  Created by Ramon Torres on 10/22/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import UIKit
@_spi(STP) import StripeUICore

extension LinkPaymentMethodPicker {

    final class Header: UIControl {
        struct Constants {
            static let contentSpacing: CGFloat = 16
            static let chevronSize: CGSize = .init(width: 24, height: 24)
            static let collapsedInsets = NSDirectionalEdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20)
            static let expandedInsets = NSDirectionalEdgeInsets(top: 20, leading: 20, bottom: 4, trailing: 20)
        }

        /// The selected payment method.
        var selectedPaymentMethod: ConsumerPaymentDetails? {
            didSet {
                contentView.paymentMethod = selectedPaymentMethod
                updateAccessibilityContent()
            }
        }

        var isExpanded: Bool = false {
            didSet {
                setNeedsLayout()
                updateAccessibilityContent()
            }
        }

        override var isHighlighted: Bool {
            didSet {
                if isHighlighted && !isExpanded {
                    backgroundColor = .linkControlHighlight
                } else {
                    backgroundColor = .clear
                }
            }
        }

        private let payWithLabel: UILabel = {
            let label = UILabel()
            label.font = LinkUI.font(forTextStyle: .body)
            label.text = "Pay with" // TODO(ramont): Localize
            label.textColor = CompatibleColor.secondaryLabel
            label.adjustsFontForContentSizeCategory = true
            return label
        }()

        private let headingLabel: UILabel = {
            let label = UILabel()
            label.font = LinkUI.font(forTextStyle: .bodyEmphasized)
            label.text = "Select a saved payment" // TODO(ramont): Localize
            label.adjustsFontForContentSizeCategory = true
            return label
        }()

        private let contentView = CellContentView()

        private let cardNumberLabel: UILabel = {
            let label = UILabel()
            label.font = UIFont.monospacedDigitSystemFont(ofSize: 14, weight: .medium)
                .scaled(withTextStyle: .body, maximumPointSize: 20)
            return label
        }()

        private lazy var chevron: UIImageView = {
            let chevron = UIImageView(image: StripeUICore.Image.icon_chevron_down.makeImage())
            chevron.contentMode = .center
            chevron.tintColor = .gray

            NSLayoutConstraint.activate([
                chevron.widthAnchor.constraint(equalToConstant: Constants.chevronSize.width),
                chevron.heightAnchor.constraint(equalToConstant: Constants.chevronSize.height)
            ])

            return chevron
        }()

        private lazy var paymentInfoStackView: UIStackView = {
            let stackView = UIStackView(arrangedSubviews: [
                payWithLabel,
                contentView
            ])

            stackView.alignment = .center
            stackView.setCustomSpacing(Constants.contentSpacing, after: payWithLabel)
            stackView.translatesAutoresizingMaskIntoConstraints = false

            return stackView
        }()

        private lazy var stackView: UIStackView = {
            let stackView = UIStackView(arrangedSubviews: [
                paymentInfoStackView,
                headingLabel,
                chevron
            ])

            stackView.axis = .horizontal
            stackView.spacing = Constants.contentSpacing
            stackView.distribution = .equalSpacing
            stackView.alignment = .center
            stackView.isLayoutMarginsRelativeArrangement = true
            stackView.translatesAutoresizingMaskIntoConstraints = false

            return stackView
        }()

        override init(frame: CGRect) {
            super.init(frame: .zero)

            addSubview(stackView)

            NSLayoutConstraint.activate([
                // Stack view
                stackView.topAnchor.constraint(equalTo: topAnchor),
                stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
                stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
                stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            ])

            isAccessibilityElement = true
            accessibilityTraits = .button

            updateAccessibilityContent()
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        private func updateAccessibilityContent() {
            if isExpanded {
                accessibilityLabel = headingLabel.text
                accessibilityHint = "Tap to close" // TODO(ramont): Localize
            } else {
                accessibilityLabel = selectedPaymentMethod?.accessibilityDescription
                accessibilityHint = "Tap to expand" // TODO(ramont): Localize
            }
        }

        override func layoutSubviews() {
            super.layoutSubviews()

            if isExpanded {
                paymentInfoStackView.isHidden = true
                headingLabel.isHidden = false
                chevron.transform = CGAffineTransform(rotationAngle: .pi)
                stackView.directionalLayoutMargins = Constants.expandedInsets
            } else {
                paymentInfoStackView.isHidden = false
                headingLabel.isHidden = true
                chevron.transform = .identity
                stackView.directionalLayoutMargins = Constants.collapsedInsets
            }
        }

        override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
            if self.point(inside: point, with: event) {
                return self
            }

            return nil
        }

    }

}
