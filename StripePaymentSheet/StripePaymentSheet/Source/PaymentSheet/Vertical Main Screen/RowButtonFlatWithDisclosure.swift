//
//  RowButtonFlatWithDisclosure.swift
//  StripePaymentSheet
//
//  Created by George Birch on 4/30/25.
//

import Foundation
@_spi(STP) import StripeUICore
import UIKit

/// A `RowButton` subclass that presents a flat layout featuring a chevron. No selected state is available for this style.
final class RowButtonFlatWithDisclosure: RowButton {
    // MARK: - Subviews
    private lazy var disclosureImageView: UIImageView = {
        let disclosureImage = appearance.embeddedPaymentElement.row.flat.disclosure.disclosureImage ?? Image.icon_chevron_right.makeImage(template: true)
        let chevronImageView = UIImageView(image: disclosureImage)
        chevronImageView.tintColor = appearance.embeddedPaymentElement.row.flat.disclosure.color
        chevronImageView.contentMode = .scaleAspectFit
        chevronImageView.translatesAutoresizingMaskIntoConstraints = false
        return chevronImageView
    }()

    override func setupUI() {
        let labelsStackView = UIStackView(arrangedSubviews: [label, sublabel].compactMap { $0 })
        labelsStackView.axis = .vertical
        labelsStackView.alignment = .leading

        let stackView = UIStackView(arrangedSubviews: [labelsStackView, accessoryView].compactMap { $0 })
        stackView.axis = .vertical
        stackView.alignment = .leading
        stackView.setCustomSpacing(8, after: labelsStackView)

        let horizontalStackView = UIStackView(arrangedSubviews: [stackView,
                                                                 defaultBadgeLabel,
                                                                 UIView.makeSpacerView(),
                                                                 promoBadge,
                                                                 disclosureImageView, ].compactMap { $0 })
        horizontalStackView.spacing = 8
        horizontalStackView.alignment = .center
        if let promoBadge {
            horizontalStackView.setCustomSpacing(12, after: promoBadge)
        }

        [imageView, horizontalStackView].compactMap { $0 }
            .forEach { view in
                view.translatesAutoresizingMaskIntoConstraints = false
                view.isAccessibilityElement = false
                addSubview(view)
            }

        // MARK: - Constraints

        // Resolve ambiguous height warning by setting these constraints w/ low priority
        let imageViewTopConstraint = imageView.topAnchor.constraint(equalTo: topAnchor, constant: 14)
        imageViewTopConstraint.priority = .defaultLow
        let imageViewBottomConstraint = imageView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -14)
        imageViewBottomConstraint.priority = .defaultLow

        let imageViewCenterYConstraint: NSLayoutConstraint
        // If we have an accessory view align the image with the top label
        if let accessoryView, !accessoryView.isHidden {
            imageViewCenterYConstraint = imageView.centerYAnchor.constraint(equalTo: label.centerYAnchor)
        } else {
            imageViewCenterYConstraint = imageView.centerYAnchor.constraint(equalTo: centerYAnchor)
        }

        let insets = appearance.embeddedPaymentElement.row.additionalInsets
        NSLayoutConstraint.activate([
            // Image view constraints
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: appearance.embeddedPaymentElement.row.paymentMethodIconLayoutMargins.leading),
            imageView.topAnchor.constraint(greaterThanOrEqualTo: topAnchor, constant: 10 + insets),
            imageView.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -10 - insets),
            imageView.heightAnchor.constraint(equalToConstant: 20),
            imageView.widthAnchor.constraint(equalToConstant: 24),
            imageViewCenterYConstraint,
            imageViewTopConstraint,
            imageViewBottomConstraint,

            // Label constraints
            horizontalStackView.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: appearance.embeddedPaymentElement.row.paymentMethodIconLayoutMargins.trailing),
            horizontalStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            horizontalStackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            horizontalStackView.topAnchor.constraint(greaterThanOrEqualTo: topAnchor, constant: insets),
            horizontalStackView.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -insets),
        ])
    }
}
