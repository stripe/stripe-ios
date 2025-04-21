//
//  RowButtonFloating.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 2/12/25.
//

import Foundation
@_spi(STP) import StripeUICore
import UIKit

/// A `RowButton` subclass that presents floating button style.
final class RowButtonFloating: RowButton {
    // MARK: - Subviews

    /// The shadow view that manages corner radius and shadows and selection border
    private lazy var shadowRoundedRect: ShadowedRoundedRectangle = {
        ShadowedRoundedRectangle(appearance: appearance)
    }()
    /// The vertical top and bottom padding to be used. Floating uses different values for insets based on if it is used in embedded or vertical mode
    private var insets: CGFloat {
        guard isEmbedded else {
            return 4.0 // 4.0 insets for vertical mode
        }

        return appearance.embeddedPaymentElement.row.additionalInsets
    }

    override func updateSelectedState() {
        super.updateSelectedState()
        shadowRoundedRect.isSelected = isSelected
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
        addAndPinSubview(shadowRoundedRect)

        let horizontalStackView = UIStackView(arrangedSubviews: [arrangedLabelAndSubLabel,
                                                                 defaultBadgeLabel,
                                                                 UIView.makeSpacerView(),
                                                                 promoBadge,
                                                                 accessoryView, ].compactMap { $0 })
        horizontalStackView.spacing = 8
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

        NSLayoutConstraint.activate([
            // Image view constraints
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            imageView.topAnchor.constraint(greaterThanOrEqualTo: topAnchor, constant: 10 + insets),
            imageView.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -10 - insets),
            imageView.heightAnchor.constraint(equalToConstant: 20),
            imageView.widthAnchor.constraint(equalToConstant: 24),
            imageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            imageViewBottomConstraint,
            imageViewTopConstraint,

            // Label constraints
            horizontalStackView.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 12),
            horizontalStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            horizontalStackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            horizontalStackView.topAnchor.constraint(equalTo: topAnchor, constant: insets),
            horizontalStackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -insets),
        ])
    }

    override func handleEvent(_ event: STPEvent) {
        // Don't make the rounded rect look disabled
        let filteredSubviews = subviews.filter { !($0 === shadowRoundedRect) }

        switch event {
        case .shouldEnableUserInteraction:
            filteredSubviews.forEach { $0.alpha = 1 }
        case .shouldDisableUserInteraction:
            filteredSubviews.forEach { $0.alpha = 0.5 }
        default:
            break
        }
    }
}
