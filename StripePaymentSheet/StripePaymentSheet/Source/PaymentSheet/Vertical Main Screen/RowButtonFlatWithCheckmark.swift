//
//  RowButtonFlatWithCheckmark.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 2/18/25.
//

import Foundation
@_spi(STP) import StripeUICore
import UIKit

/// A `RowButton` subclass that presents a flat layout featuring a checkmark for the selected state.
final class RowButtonFlatWithCheckmark: RowButton {
    // MARK: - Subviews
    private lazy var checkmarkImageView: UIImageView = {
        let checkmarkImageView = UIImageView(image: Image.embedded_check.makeImage(template: true))
        checkmarkImageView.tintColor = appearance.embeddedPaymentElement.row.flat.checkmark.color ?? appearance.colors.primary
        checkmarkImageView.contentMode = .scaleAspectFit
        checkmarkImageView.isHidden = true
        checkmarkImageView.translatesAutoresizingMaskIntoConstraints = false
        return checkmarkImageView
    }()

    override func updateSelectedState() {
        super.updateSelectedState()
        checkmarkImageView.isHidden = !isSelected
    }

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
                                                                 checkmarkImageView, ].compactMap { $0 })
        horizontalStackView.spacing = 8
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
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            imageView.topAnchor.constraint(greaterThanOrEqualTo: topAnchor, constant: 10 + insets),
            imageView.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -10 - insets),
            imageView.heightAnchor.constraint(equalToConstant: 20),
            imageView.widthAnchor.constraint(equalToConstant: 24),
            imageViewCenterYConstraint,
            imageViewTopConstraint,
            imageViewBottomConstraint,

            // Label constraints
            horizontalStackView.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 12),
            horizontalStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            horizontalStackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            horizontalStackView.topAnchor.constraint(greaterThanOrEqualTo: topAnchor, constant: insets),
            horizontalStackView.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -insets),
        ])
    }
}
