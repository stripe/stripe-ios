//
//  RowButtonFlatWithChevron.swift
//  StripePaymentSheet
//
//  Created by George Birch on 4/30/25.
//

import Foundation
@_spi(STP) import StripeUICore
import UIKit

/// A `RowButton` subclass that presents a flat layout featuring a chevron. No selected state is available for this style.
final class RowButtonFlatWithChevron: RowButton {
    // MARK: - Subviews
    private lazy var chevronView: UIImageView = {
//        let chevronImageView = UIImageView(image: Image.icon_chevron_right.makeImage(template: true))

//        chevronImageView.tintColor = appearance.embeddedPaymentElement.row.flat.chevron.color
//        chevronImageView.contentMode = .scaleAspectFit
//        let chevronImageView = UIImageView(image: Image.polling_error.makeImage(template: true))
        let chevronImageView = UIImageView(image: appearance.embeddedPaymentElement.row.flat.chevron.image)
        chevronImageView.translatesAutoresizingMaskIntoConstraints = false
        return chevronImageView
    }()

    override func setupUI() {
        // just labels
        let labelsStackView = UIStackView(arrangedSubviews: [label, sublabel].compactMap { $0 })
        labelsStackView.axis = .vertical
        labelsStackView.alignment = .leading

        // lables + accessory stack (accessory - e.g. change SPM)
        let stackView = UIStackView(arrangedSubviews: [labelsStackView, accessoryView].compactMap { $0 })
        stackView.axis = .vertical
        stackView.alignment = .leading
        stackView.setCustomSpacing(8, after: labelsStackView)

        // top level horizontal stack view
        let horizontalStackView = UIStackView(arrangedSubviews: [stackView,
                                                                 defaultBadgeLabel,
                                                                 UIView.makeSpacerView(),
                                                                 promoBadge,
                                                                 /*chevronView,*/ ].compactMap { $0 })
        horizontalStackView.spacing = 8
        if let promoBadge {
            horizontalStackView.setCustomSpacing(12, after: promoBadge)
        }

        // imageView = payment method logo
        [imageView, horizontalStackView, chevronView].compactMap { $0 }
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
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            imageView.topAnchor.constraint(greaterThanOrEqualTo: topAnchor, constant: 10 + insets),
            imageView.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -10 - insets),
            imageView.heightAnchor.constraint(equalToConstant: 20),
            imageView.widthAnchor.constraint(equalToConstant: 24),
            imageViewCenterYConstraint,
            imageViewTopConstraint,
            imageViewBottomConstraint,

            // Label constraints
            // lock left to logo image
            horizontalStackView.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 12),
            // lock right to 12 from trailing edge of view
//            horizontalStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            // ????
            horizontalStackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            // great than equal to allows the content of the row to grow, but not shrink too small
            horizontalStackView.topAnchor.constraint(greaterThanOrEqualTo: topAnchor, constant: insets),
            horizontalStackView.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -insets),

            chevronView.leadingAnchor.constraint(equalTo: horizontalStackView.trailingAnchor),
            chevronView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            chevronView.centerYAnchor.constraint(equalTo: centerYAnchor),
            chevronView.heightAnchor.constraint(equalToConstant: appearance.embeddedPaymentElement.row.flat.chevron.size),
            chevronView.widthAnchor.constraint(equalToConstant: appearance.embeddedPaymentElement.row.flat.chevron.size),
        ])
    }
}
