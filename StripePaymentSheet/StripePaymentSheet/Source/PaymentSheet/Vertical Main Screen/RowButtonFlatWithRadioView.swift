//
//  RowButtonFlatWithRadioView.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 2/11/25.
//

import Foundation
@_spi(STP) import StripeUICore
import UIKit

/// A standalone view dedicated to the "flat with radio" RowButton style.
final class RowButtonFlatWithRadioView: UIView, RowButtonContent {
    let appearance: PaymentSheet.Appearance

    // MARK: - Subviews

    /// The radio control
    private let radioButton: RadioButton
    /// Typically the payment method icon or brand image
    private let imageView: UIImageView
    /// The main label for the payment method name
    private let label: UILabel
    /// The subtitle label, e.g. “Pay over time with Affirm”
    private let sublabel: UILabel
    /// An accessory view that is displayed on the trailing end of the content view, e.g. "View More"
    private let rightAccessoryView: UIView?
    /// The label indicating if this is the default saved payment method
    private let defaultBadgeLabel: UILabel?
    /// The view indicating any incentives associated with this payment method
    private let promoBadge: PromoBadgeView?

    // MARK: - State

    var isSelected: Bool = false {
        didSet {
            radioButton.isOn = isSelected
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
        promoBadge: PromoBadgeView?
    ) {
        self.appearance = appearance
        self.imageView = imageView
        self.label = RowButton.makeRowButtonLabel(text: text, appearance: appearance)
        self.sublabel = RowButton.makeRowButtonSublabel(text: subtext, appearance: appearance)
        self.rightAccessoryView = rightAccessoryView
        self.defaultBadgeLabel = RowButton.makeRowButtonDefaultBadgeLabel(badgeText: defaultBadgeText, appearance: appearance)
        self.promoBadge = promoBadge
        self.radioButton = RadioButton(appearance: appearance)
        self.radioButton.isUserInteractionEnabled = false

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

    func setKeyContent(alpha: CGFloat) {
        [imageView, label, sublabel].compactMap { $0 }.forEach {
            $0.alpha = alpha
        }
    }
}

// MARK: - UI Setup

private extension RowButtonFlatWithRadioView {
    func setupUI() {
        backgroundColor = appearance.colors.componentBackground

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
