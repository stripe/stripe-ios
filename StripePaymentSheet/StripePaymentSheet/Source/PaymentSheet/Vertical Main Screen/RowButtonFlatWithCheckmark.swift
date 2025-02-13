//
//  RowButtonFlatWithCheckmark.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 2/12/25.
//

import Foundation
@_spi(STP) import StripeUICore
import UIKit

/// A standalone view dedicated to the "flat with radio" RowButton style.
final class RowButtonFlatWithCheckmark: UIView, RowButtonContent {
    let appearance: PaymentSheet.Appearance

    // MARK: - Subviews
    private lazy var checkmarkImageView: UIImageView = {
        let checkmarkImageView = UIImageView(image: Image.embedded_check.makeImage(template: true))
        checkmarkImageView.tintColor = appearance.embeddedPaymentElement.row.flat.checkmark.color ?? appearance.colors.primary
        checkmarkImageView.contentMode = .scaleAspectFit
        checkmarkImageView.isHidden = true
        checkmarkImageView.translatesAutoresizingMaskIntoConstraints = false
        return checkmarkImageView
    }()
    /// Typically the payment method icon or brand image
    private let imageView: UIImageView
    /// The main label for the payment method name
    private let label: UILabel
    /// The subtitle label, e.g. “Pay over time with Affirm”
    private let sublabel: UILabel
    /// For layout convenience: if we have an accessory view on the bottom (e.g. a brand logo, etc.)
    private let bottomAccessoryView: UIView?
    /// The label indicating if this is the default saved payment method
    private let defaultBadgeLabel: UILabel?
    /// The view indicating any incentives associated with this payment method
    private let promoBadge: PromoBadgeView?

    // MARK: - State

    var isSelected: Bool = false {
        didSet {
            checkmarkImageView.isHidden = !isSelected
            // Default badge font is heavier when the row is selected
            defaultBadgeLabel?.font = isSelected ? appearance.selectedDefaultBadgeFont : appearance.defaultBadgeFont
            layoutIfNeeded() // Required to prevent checkmarkImageView from animating in strangely
        }
    }

    var hasSubtext: Bool {
        guard let subtext = sublabel.text else { return false }
        return !subtext.isEmpty
    }

    var isDisplayingAccessoryView: Bool {
        get {
            guard let bottomAccessoryView else {
                return false
            }
            return !bottomAccessoryView.isHidden
        }
        set {
            bottomAccessoryView?.isHidden = !newValue
        }
    }

    init(
        appearance: PaymentSheet.Appearance,
        imageView: UIImageView,
        text: String,
        subtext: String? = nil,
        bottomAccessoryView: UIView? = nil,
        defaultBadgeText: String?,
        promoBadge: PromoBadgeView?
    ) {
        self.appearance = appearance
        self.imageView = imageView
        self.label = RowButton.makeRowButtonLabel(text: text, appearance: appearance)
        self.sublabel = RowButton.makeRowButtonSublabel(text: subtext, appearance: appearance)
        self.bottomAccessoryView = bottomAccessoryView
        self.defaultBadgeLabel = RowButton.makeRowButtonDefaultBadgeLabel(badgeText: defaultBadgeText, appearance: appearance)
        self.promoBadge = promoBadge

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

private extension RowButtonFlatWithCheckmark {
    func setupUI() {
        backgroundColor = appearance.colors.componentBackground

        let labelsStackView = UIStackView(arrangedSubviews: [label, sublabel].compactMap { $0 })
        labelsStackView.axis = .vertical
        labelsStackView.alignment = .leading

        let stackView = UIStackView(arrangedSubviews: [labelsStackView, bottomAccessoryView].compactMap { $0 })
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
        if let bottomAccessoryView, !bottomAccessoryView.isHidden {
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
