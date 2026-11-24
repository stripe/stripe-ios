//
//  LinkShippingAddressPicker-Header.swift
//  StripePaymentSheet
//
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

@_spi(InternalOnlyAPI) import StripeUICore
import UIKit

extension LinkShippingAddressPicker {

    final class Header: UIControl {
        typealias Constants = LinkPaymentMethodPicker.Header.Constants

        enum Strings {
            static let shipping = STPLocalizedString(
                "Shipping",
                "Label for a section displaying the shipping address."
            )
        }

        /// The selected shipping address.
        private var selectedShippingAddress: ShippingAddressesResponse.ShippingAddress? {
            didSet {
                contentView.shippingAddress = selectedShippingAddress
                updateChevron()
                updateAccessibilityContent()
            }
        }

        private var collapsable: Bool {
            selectedShippingAddress != nil
        }

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

        private let shippingLabel: UILabel = {
            let label = UILabel()
            label.font = LinkUI.font(forTextStyle: .body)
            label.textColor = .linkTextTertiary
            label.text = Strings.shipping
            label.adjustsFontForContentSizeCategory = true
            label.setContentCompressionResistancePriority(.required, for: .horizontal)
            label.translatesAutoresizingMaskIntoConstraints = false
            return label
        }()

        private let headingLabel: UILabel = {
            let label = UILabel()
            label.font = LinkUI.font(forTextStyle: .body)
            label.textColor = .linkTextTertiary
            label.text = STPLocalizedString(
                "Shipping addresses",
                "Title for a section listing one or more shipping addresses."
            )
            label.adjustsFontForContentSizeCategory = true
            return label
        }()

        private let contentView = CellContentView()

        private lazy var chevron: UIImageView = {
            let chevron = UIImageView(image: StripeUICore.Image.icon_chevron_down.makeImage(template: true))
            chevron.contentMode = .center

            NSLayoutConstraint.activate([
                chevron.widthAnchor.constraint(equalToConstant: Constants.chevronSize.width),
                chevron.heightAnchor.constraint(equalToConstant: Constants.chevronSize.height),
            ])

            return chevron
        }()

        private lazy var shippingInfoStackView: UIStackView = {
            let stackView = UIStackView(arrangedSubviews: [
                shippingLabel,
                contentView,
            ])

            stackView.alignment = .center
            stackView.spacing = Constants.contentSpacing
            stackView.translatesAutoresizingMaskIntoConstraints = false

            let shippingLabelWidth = shippingLabel.widthAnchor.constraint(equalToConstant: LinkPaymentMethodPicker.widthForHeaderLabels)
            shippingLabelWidth.priority = .defaultLow
            shippingLabelWidth.isActive = true

            return stackView
        }()

        private lazy var stackView: UIStackView = {
            let stackView = UIStackView(arrangedSubviews: [
                shippingInfoStackView,
                headingLabel,
                chevron,
            ])

            stackView.axis = .horizontal
            stackView.spacing = Constants.contentSpacing
            stackView.alignment = .center
            stackView.isLayoutMarginsRelativeArrangement = true
            stackView.translatesAutoresizingMaskIntoConstraints = false

            return stackView
        }()

        override init(frame: CGRect) {
            super.init(frame: .zero)

            addAndPinSubview(stackView)

            isAccessibilityElement = true
            accessibilityTraits = .button

            updateChevron()
            updateAccessibilityContent()
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        func setSelectedShippingAddress(_ selectedShippingAddress: ShippingAddressesResponse.ShippingAddress?) {
            self.selectedShippingAddress = selectedShippingAddress
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
                accessibilityLabel = selectedShippingAddress?.accessibilityDescription
                accessibilityHint = STPLocalizedString(
                    "Tap to expand",
                    "Accessibility hint to tell the user that they can tap to reveal additional content."
                )
            }
        }

        override func layoutSubviews() {
            super.layoutSubviews()

            if isExpanded {
                shippingInfoStackView.isHidden = true
                headingLabel.isHidden = false
                stackView.directionalLayoutMargins = Constants.expandedInsets
            } else {
                shippingInfoStackView.isHidden = false
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
