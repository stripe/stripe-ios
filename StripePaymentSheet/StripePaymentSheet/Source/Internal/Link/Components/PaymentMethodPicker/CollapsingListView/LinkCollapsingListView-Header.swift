//
//  LinkCollapsingListView-Header.swift
//  StripePaymentSheet
//
//  Created by Ramon Torres on 10/22/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

@_spi(STP) import StripeUICore
import UIKit

extension LinkCollapsingListView {

    class Header: UIControl {
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

        // Indicates whether the header should appear collapsable or not.
        // The header is collapsable when the currently selected payment method is supported.
        var collapsable: Bool = false

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

        let collapsedLabel: UILabel = {
            let label = UILabel()
            label.textColor = .linkTextTertiary
            label.font = LinkUI.font(forTextStyle: .body)
            label.adjustsFontForContentSizeCategory = true
            label.translatesAutoresizingMaskIntoConstraints = false
            return label
        }()

        let headingLabel: UILabel = {
            let label = UILabel()
            label.font = LinkUI.font(forTextStyle: .body)
            label.textColor = .linkTextTertiary

            label.adjustsFontForContentSizeCategory = true
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

        lazy var collapsedStackView: UIStackView = {
            let stackView = UIStackView(arrangedSubviews: [
                collapsedLabel,
            ])

            stackView.alignment = .center
            stackView.setCustomSpacing(Constants.contentSpacing, after: collapsedLabel)
            stackView.translatesAutoresizingMaskIntoConstraints = false

            let payWithLabelWidth = collapsedLabel.widthAnchor.constraint(equalToConstant: LinkPaymentMethodPicker.widthForHeaderLabels)
            payWithLabelWidth.priority = .defaultLow

            NSLayoutConstraint.activate([
                payWithLabelWidth,
            ])

            return stackView
        }()

        private lazy var stackView: UIStackView = {
            let stackView = UIStackView(arrangedSubviews: [
                collapsedStackView,
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

        func updateChevron() {
            if isExpanded {
                chevron.transform = CGAffineTransform(rotationAngle: .pi)
            } else {
                chevron.transform = .identity
            }
            chevron.tintColor = .linkIconTertiary
            chevron.isHidden = !collapsable
        }

        func updateAccessibilityContent() {
            if isExpanded {
                accessibilityHint = STPLocalizedString(
                    "Tap to close",
                    "Accessibility hint to tell the user that they can tap to hide additional content."
                )
            } else {
                accessibilityHint = STPLocalizedString(
                    "Tap to expand",
                    "Accessibility hint to tell the user that they can tap to reveal additional content."
                )
            }
        }

        override func layoutSubviews() {
            super.layoutSubviews()

            if isExpanded {
                collapsedStackView.isHidden = true
                headingLabel.isHidden = false
                stackView.directionalLayoutMargins = Constants.expandedInsets
            } else {
                collapsedStackView.isHidden = false
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
