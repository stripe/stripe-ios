//
//  LinkPaymentMethodPicker-Header.swift
//  StripePaymentSheet
//
//  Created by Ramon Torres on 10/22/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

@_spi(STP) import StripeUICore
import UIKit

extension LinkPaymentMethodPicker {

    final class Header: UIControl {
        struct Constants {
            static let contentSpacing: CGFloat = 16
            static let chevronSize: CGSize = .init(width: 24, height: 24)
            static let collapsedInsets = NSDirectionalEdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20)
            static let expandedInsets = NSDirectionalEdgeInsets(top: 20, leading: 20, bottom: 4, trailing: 20)
        }

        enum Strings {
            static let payment = STPLocalizedString(
                "Payment",
                "Label for a section displaying payment details."
            )
        }

        /// The selected payment method.
        private(set) var selectedPaymentMethod: ConsumerPaymentDetails? {
            didSet {
                updateChevron()
                contentView.paymentMethod = selectedPaymentMethod
                updateAccessibilityContent()
            }
        }

        // Indicates whether the header should appear collapsable or not.
        // The header is collapsable when the currently selected payment method is supported.
        private(set) var collapsable: Bool = false

        var isExpanded: Bool = false {
            didSet {
                setNeedsLayout()
                updateChevron()
                updateAccessibilityContent()
            }
        }

        override var isHighlighted: Bool {
            didSet {
                if isHighlighted && !isExpanded {
                    backgroundColor = .linkSurfaceTertiary
                } else {
                    backgroundColor = .clear
                }
            }
        }

        private let payWithLabel: UILabel = {
            let label = UILabel()
            label.font = LinkUI.font(forTextStyle: .body)
            label.textColor = .linkTextTertiary
            label.text = Strings.payment
            label.adjustsFontForContentSizeCategory = true
            label.translatesAutoresizingMaskIntoConstraints = false
            return label
        }()

        private let headingLabel: UILabel = {
            let label = UILabel()
            label.font = LinkUI.font(forTextStyle: .body)
            label.textColor = .linkTextTertiary
            label.text = STPLocalizedString(
                "Payment methods",
                "Title for a section listing one or more payment methods."
            )
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
            let chevron = UIImageView(image: StripeUICore.Image.icon_chevron_down.makeImage(template: true))
            chevron.contentMode = .center

            NSLayoutConstraint.activate([
                chevron.widthAnchor.constraint(equalToConstant: Constants.chevronSize.width),
                chevron.heightAnchor.constraint(equalToConstant: Constants.chevronSize.height),
            ])

            return chevron
        }()

        private lazy var paymentInfoStackView: UIStackView = {
            let stackView = UIStackView(arrangedSubviews: [
                payWithLabel,
                contentView,
            ])

            stackView.alignment = .center
            stackView.setCustomSpacing(Constants.contentSpacing, after: payWithLabel)
            stackView.translatesAutoresizingMaskIntoConstraints = false

            let payWithLabelWidth = payWithLabel.widthAnchor.constraint(equalToConstant: LinkPaymentMethodPicker.widthForHeaderLabels)
            payWithLabelWidth.priority = .defaultLow

            NSLayoutConstraint.activate([
                payWithLabelWidth,
            ])

            return stackView
        }()

        private lazy var stackView: UIStackView = {
            let stackView = UIStackView(arrangedSubviews: [
                paymentInfoStackView,
                headingLabel,
                chevron,
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

            updateChevron()
            updateAccessibilityContent()
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        func setSelectedPaymentMethod(selectedPaymentMethod: ConsumerPaymentDetails?, supported: Bool) {
            self.collapsable = supported
            self.selectedPaymentMethod = selectedPaymentMethod
        }

        private func updateChevron() {
            if isExpanded {
                chevron.transform = CGAffineTransform(rotationAngle: .pi)
            } else {
                chevron.transform = .identity
            }
            chevron.tintColor = .linkIconTertiary
            chevron.isHidden = !collapsable
        }

        private func updateAccessibilityContent() {
            if isExpanded {
                accessibilityLabel = headingLabel.text
                accessibilityHint = STPLocalizedString(
                    "Tap to close",
                    "Accessibility hint to tell the user that they can tap to hide additional content."
                )
            } else {
                accessibilityLabel = selectedPaymentMethod?.accessibilityDescription
                accessibilityHint = STPLocalizedString(
                    "Tap to expand",
                    "Accessibility hint to tell the user that they can tap to reveal additional content."
                )
            }
        }

        override func layoutSubviews() {
            super.layoutSubviews()

            if isExpanded {
                paymentInfoStackView.isHidden = true
                headingLabel.isHidden = false
                stackView.directionalLayoutMargins = Constants.expandedInsets
            } else {
                paymentInfoStackView.isHidden = false
                headingLabel.isHidden = true
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
