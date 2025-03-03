//
//  RowButtonFlatWithRadioView.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 2/11/25.
//

import Foundation
@_spi(STP) import StripeUICore
import UIKit

/// A `RowButton` subclass that presents a flat layout featuring a radio button for the selected state.
final class RowButtonFlatWithRadioView: RowButton {
    // MARK: - Subviews

    /// The radio control
    private lazy var radioButton: RadioButton = {
        let radioButton = RadioButton(appearance: appearance)
        radioButton.isUserInteractionEnabled = false
        return radioButton
    }()

    override func updateSelectedState() {
        super.updateSelectedState()
        radioButton.isOn = isSelected
    }

    override func setupUI() {
        backgroundColor = appearance.colors.componentBackground

        // Add common subviews
        let labelsStackView = UIStackView(arrangedSubviews: [label, sublabel].compactMap { $0 })
        labelsStackView.axis = .vertical
        labelsStackView.alignment = .leading

        let horizontalStackView = UIStackView(arrangedSubviews: [labelsStackView,
                                                                 defaultBadgeLabel,
                                                                 UIView.makeSpacerView(),
                                                                 promoBadge,
                                                                 accessoryView, ].compactMap { $0 })
        horizontalStackView.spacing = 8

        [radioButton, imageView, horizontalStackView].compactMap { $0 }
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

        let insets = appearance.embeddedPaymentElement.row.additionalInsets
        NSLayoutConstraint.activate([
            // Radio button constraints
            radioButton.leadingAnchor.constraint(equalTo: leadingAnchor),
            radioButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            radioButton.widthAnchor.constraint(equalToConstant: 18),
            radioButton.heightAnchor.constraint(equalToConstant: 18),

            // Image view constraints
            imageView.leadingAnchor.constraint(equalTo: radioButton.trailingAnchor, constant: 12),
            imageView.topAnchor.constraint(greaterThanOrEqualTo: topAnchor, constant: 10 + insets),
            imageView.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -10 - insets),
            imageView.heightAnchor.constraint(equalToConstant: 20),
            imageView.widthAnchor.constraint(equalToConstant: 24),
            imageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            imageViewTopConstraint,
            imageViewBottomConstraint,

            // Label constraints
            horizontalStackView.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 12),
            horizontalStackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            horizontalStackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            horizontalStackView.topAnchor.constraint(greaterThanOrEqualTo: topAnchor, constant: insets),
            horizontalStackView.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -insets),
        ])
    }
}
