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

    private lazy var arrangedLabelAndSubLabel: UIView = {
        let containingView = UIView()
        let spacerTop = UIView()
        let spacerBottom = UIView()

        let labelsStackView = UIStackView(arrangedSubviews: [label, sublabel].compactMap { $0 })
        labelsStackView.axis = .vertical
        labelsStackView.alignment = .leading

        // Create a vertical stack view to manage the distribution of space
        let verticalStackView = UIStackView(arrangedSubviews: [spacerTop, labelsStackView, spacerBottom])
        verticalStackView.axis = .vertical
        verticalStackView.alignment = .fill
        verticalStackView.distribution = .fill
        verticalStackView.translatesAutoresizingMaskIntoConstraints = false
        containingView.addSubview(verticalStackView)

        // Allow spacers to expand w/ low content hugging priority
        spacerTop.setContentHuggingPriority(.defaultLow, for: .vertical)
        spacerBottom.setContentHuggingPriority(.defaultLow, for: .vertical)

        // Make labels not expand by giving them high content hugging priority
        labelsStackView.setContentHuggingPriority(.defaultHigh, for: .vertical)

        NSLayoutConstraint.activate([
            verticalStackView.topAnchor.constraint(equalTo: containingView.topAnchor),
            verticalStackView.bottomAnchor.constraint(equalTo: containingView.bottomAnchor),
            verticalStackView.leadingAnchor.constraint(equalTo: containingView.leadingAnchor),
            verticalStackView.trailingAnchor.constraint(equalTo: containingView.trailingAnchor),

            // Make spacers grow equally if needed
            spacerTop.heightAnchor.constraint(equalTo: spacerBottom.heightAnchor),
        ])
        return containingView
    }()

    override func setupUI() {
        let horizontalStackView = UIStackView(arrangedSubviews: [arrangedLabelAndSubLabel,
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
            horizontalStackView.topAnchor.constraint(equalTo: topAnchor, constant: insets),
            horizontalStackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -insets),
        ])
    }
}
