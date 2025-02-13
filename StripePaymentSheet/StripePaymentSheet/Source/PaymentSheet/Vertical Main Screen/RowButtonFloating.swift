//
//  RowButtonFloating.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 2/12/25.
//

import Foundation
@_spi(STP) import StripeUICore
import UIKit

final class RowButtonFloating: UIView, RowButtonContent {
    let appearance: PaymentSheet.Appearance

    // MARK: - Subviews

    /// Typically the payment method icon or brand image
    private let imageView: UIImageView
    /// The main label for the payment method name
    private let label: UILabel
    /// The subtitle label, e.g. “Pay over time with Affirm”
    private let sublabel: UILabel
    /// For layout convenience: if we have an accessory view to the right (e.g. a brand logo, etc.)
    private let rightAccessoryView: UIView?
    /// The label indicating if this is the default saved payment method
    private let defaultBadgeLabel: UILabel?
    /// The view indicating any incentives associated with this payment method
    private let promoBadge: PromoBadgeView?
    /// The vertical top and bottom padding to be used. Floating uses different values for insets based on if it is used in embedded or vertical mode
    private let insets: CGFloat

    // MARK: - State

    var isSelected: Bool = false {
        didSet {
            // Default badge font is heavier when the row is selected
            defaultBadgeLabel?.font = isSelected ? appearance.selectedDefaultBadgeFont : appearance.defaultBadgeFont
        }
    }

    var hasSubtext: Bool {
        guard let subtext = sublabel.text else { return false }
        return !subtext.isEmpty
    }

    var isDisplayingAccessoryView: Bool {
        get {
            guard let rightAccessoryView else {
                return false
            }
            return !rightAccessoryView.isHidden
        }
        set {
            rightAccessoryView?.isHidden = !newValue
        }
    }

    init(
        appearance: PaymentSheet.Appearance,
        imageView: UIImageView,
        text: String,
        subtext: String? = nil,
        rightAccessoryView: UIView? = nil,
        defaultBadgeText: String?,
        promoBadge: PromoBadgeView?,
        insets: CGFloat
    ) {
        self.appearance = appearance
        self.imageView = imageView
        self.label = RowButton.makeRowButtonLabel(text: text, appearance: appearance)
        self.sublabel = RowButton.makeRowButtonSublabel(text: subtext, appearance: appearance)
        self.rightAccessoryView = rightAccessoryView
        self.defaultBadgeLabel = RowButton.makeRowButtonDefaultBadgeLabel(badgeText: defaultBadgeText, appearance: appearance)
        self.promoBadge = promoBadge
        self.insets = insets

        super.init(frame: .zero)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setSublabel(text: String?) {
        guard let text else {
            sublabel.text = nil
            sublabel.isHidden = true
            return
        }

        sublabel.text = text
        sublabel.isHidden = text.isEmpty
    }
}

// MARK: - UI Setup

private extension RowButtonFloating {
    func setupUI() {
        // Add common subviews
        let labelsStackView = UIStackView(arrangedSubviews: [label, sublabel].compactMap { $0 })
        labelsStackView.axis = .vertical
        labelsStackView.alignment = .leading

        let horizontalStackView = UIStackView(arrangedSubviews: [labelsStackView,
                                                                 defaultBadgeLabel,
                                                                 UIView.makeSpacerView(),
                                                                 promoBadge,
                                                                 rightAccessoryView, ].compactMap { $0 })
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
            horizontalStackView.topAnchor.constraint(greaterThanOrEqualTo: topAnchor, constant: insets),
            horizontalStackView.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -insets),
        ])
    }
}
