//
//  RowButton.swift
//  StripePaymentSheet
//
//  Created by Yuki Tokuhiro on 5/13/24.
//

@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripePaymentsUI
@_spi(STP) import StripeUICore
import UIKit

/// A selectable button used in vertical mode to display payment methods.
class RowButton: UIView {
    private let shadowRoundedRect: ShadowedRoundedRectangle
    let appearance: PaymentSheet.Appearance
    let didTap: (RowButton) -> Void
    var isSelected: Bool = false {
        didSet {
            shadowRoundedRect.isSelected = isSelected
            updateAccessibilityTraits()
        }
    }

    /// When enabled the `didTap` closure will be called when the button is tapped. When false the `didTap` closure will not be called on taps
    var isEnabled: Bool = true {
        didSet {
            updateAccessibilityTraits()
        }
    }

    var heightConstraint: NSLayoutConstraint?

    func updateAccessibilityTraits() {
        var traits: UIAccessibilityTraits = [.button]
        if isSelected {
            traits.insert(.selected)
        }
        if !isEnabled {
            traits.insert(.notEnabled)
        }
        shadowRoundedRect.accessibilityTraits = traits
    }

    init(appearance: PaymentSheet.Appearance, imageView: UIImageView, text: String, subtext: String? = nil, rightAccessoryView: UIView? = nil, didTap: @escaping (RowButton) -> Void) {
        self.appearance = appearance
        self.didTap = didTap
        self.shadowRoundedRect = ShadowedRoundedRectangle(appearance: appearance, borderScaleFactor: 1.5)
        super.init(frame: .zero)

        // Label and sublabel
        let label = UILabel.makeVerticalRowButtonLabel(text: text, appearance: appearance)
        label.isAccessibilityElement = false
        let labelsStackView = UIStackView(arrangedSubviews: [
            label,
        ])
        if let subtext {
            let sublabel = UILabel()
            sublabel.font = appearance.scaledFont(for: appearance.font.base.regular, style: .caption1, maximumPointSize: 20)
            sublabel.numberOfLines = 1
            sublabel.adjustsFontSizeToFitWidth = true
            sublabel.adjustsFontForContentSizeCategory = true
            sublabel.text = subtext
            sublabel.textColor = appearance.colors.componentPlaceholderText
            labelsStackView.addArrangedSubview(sublabel)
        }
        labelsStackView.axis = .vertical
        labelsStackView.alignment = .leading

        addAndPinSubview(shadowRoundedRect)

        if let rightAccessoryView {
            rightAccessoryView.translatesAutoresizingMaskIntoConstraints = false
            addSubview(rightAccessoryView)
            NSLayoutConstraint.activate([
                rightAccessoryView.topAnchor.constraint(equalTo: topAnchor),
                rightAccessoryView.bottomAnchor.constraint(equalTo: bottomAnchor),
                rightAccessoryView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            ])
        }

        for view in [imageView, labelsStackView] {
            view.translatesAutoresizingMaskIntoConstraints = false
            view.isUserInteractionEnabled = false
            view.isAccessibilityElement = false
            addSubview(view)
        }

        // Resolve ambiguous height warning by setting these constraints w/ low priority
        let imageViewTopConstraint = imageView.topAnchor.constraint(equalTo: topAnchor, constant: 14)
        imageViewTopConstraint.priority = .defaultLow
        let imageViewBottomConstraint = imageView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -14)
        imageViewBottomConstraint.priority = .defaultLow

        // To make all RowButtons the same height, set our height to the tallest variant (a RowButton w/ text and subtext)
        // Don't do this if we *are* the tallest variant; otherwise we'll infinite loop!
        if subtext == nil {
            heightConstraint = heightAnchor.constraint(equalToConstant: Self.calculateTallestHeight(appearance: appearance))
            heightConstraint?.isActive = true
        }

        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            imageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            imageView.topAnchor.constraint(greaterThanOrEqualTo: topAnchor, constant: 14),
            imageView.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -14),
            imageView.heightAnchor.constraint(equalToConstant: 20),
            imageView.widthAnchor.constraint(equalToConstant: 24),

            labelsStackView.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 12),
            labelsStackView.trailingAnchor.constraint(equalTo: rightAccessoryView?.leadingAnchor ?? trailingAnchor, constant: -12),
            labelsStackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            labelsStackView.topAnchor.constraint(greaterThanOrEqualTo: topAnchor, constant: 4),
            labelsStackView.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -4),

            imageViewBottomConstraint,
            imageViewTopConstraint,
        ])

        shadowRoundedRect.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTap)))

        // Accessibility
        // Subviews of an accessibility element are ignored
        isAccessibilityElement = false
        accessibilityIdentifier = text // Just for test purposes
        accessibilityElements = [shadowRoundedRect, rightAccessoryView].compactMap { $0 }
        shadowRoundedRect.accessibilityIdentifier = text
        shadowRoundedRect.accessibilityLabel = text
        shadowRoundedRect.isAccessibilityElement = true
        updateAccessibilityTraits()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func handleTap() {
        guard isEnabled else { return }
        didTap(self)
    }

#if !canImport(CompositorServices)
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        // Update the height so that RowButtons heights w/o subtext match those with subtext
        heightConstraint?.isActive = false
        heightConstraint = heightAnchor.constraint(equalToConstant: Self.calculateTallestHeight(appearance: appearance))
        heightConstraint?.isActive = true
        super.traitCollectionDidChange(previousTraitCollection)
    }
#endif

    static func calculateTallestHeight(appearance: PaymentSheet.Appearance) -> CGFloat {
        let imageView = UIImageView(image: Image.link_icon.makeImage())
        imageView.contentMode = .scaleAspectFit
        let tallestRowButton = RowButton(appearance: appearance, imageView: imageView, text: "Dummy text", subtext: "Dummy subtext") { _ in }
        let size = tallestRowButton.systemLayoutSizeFitting(.init(width: 320, height: UIView.noIntrinsicMetric))
        return size.height
    }
}

// MARK: - Helpers
extension RowButton {
    static func makeForPaymentMethodType(paymentMethodType: PaymentSheet.PaymentMethodType, subtitle: String? = nil, savedPaymentMethodType: STPPaymentMethodType?, appearance: PaymentSheet.Appearance, didTap: @escaping (RowButton) -> Void) -> RowButton {
        let imageView = PaymentMethodTypeImageView(paymentMethodType: paymentMethodType, backgroundColor: appearance.colors.componentBackground)
        imageView.contentMode = .scaleAspectFit
        // Special case "New card" vs "Card" title
        let text: String = {
            if savedPaymentMethodType == .card && paymentMethodType == .stripe(.card) {
                return .Localized.new_card
            }
            return paymentMethodType.displayName
        }()
        return RowButton(appearance: appearance, imageView: imageView, text: text, subtext: subtitle, didTap: didTap)
    }

    static func makeForApplePay(appearance: PaymentSheet.Appearance, didTap: @escaping (RowButton) -> Void) -> RowButton {
        // Apple Pay logo has built-in padding and ends up looking too small; compensate with insets
        let applePayLogo = Image.apple_pay_mark.makeImage().withAlignmentRectInsets(UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8))
        let imageView = UIImageView(image: applePayLogo)
        imageView.contentMode = .scaleAspectFit
        return RowButton(appearance: appearance, imageView: imageView, text: String.Localized.apple_pay, didTap: didTap)
    }

    static func makeForLink(appearance: PaymentSheet.Appearance, didTap: @escaping (RowButton) -> Void) -> RowButton {
        let imageView = UIImageView(image: Image.link_icon.makeImage())
        imageView.contentMode = .scaleAspectFit
        let button = RowButton(appearance: appearance, imageView: imageView, text: STPPaymentMethodType.link.displayName, subtext: .Localized.link_subtitle_text, didTap: didTap)
        button.shadowRoundedRect.accessibilityLabel = String.Localized.pay_with_link
        return button
    }

    static func makeForSavedPaymentMethod(paymentMethod: STPPaymentMethod, appearance: PaymentSheet.Appearance, rightAccessoryView: UIView? = nil, didTap: @escaping (RowButton) -> Void) -> RowButton {
        let imageView = UIImageView(image: paymentMethod.makeSavedPaymentMethodRowImage())
        imageView.contentMode = .scaleAspectFit
        let button = RowButton(appearance: appearance, imageView: imageView, text: paymentMethod.paymentSheetLabel, rightAccessoryView: rightAccessoryView, didTap: didTap)
        button.shadowRoundedRect.accessibilityLabel = paymentMethod.paymentSheetAccessibilityLabel
        return button
    }
}
