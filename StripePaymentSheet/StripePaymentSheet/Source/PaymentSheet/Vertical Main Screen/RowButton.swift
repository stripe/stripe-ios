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
    let imageView: UIImageView
    let label: UILabel
    let sublabel: UILabel?
    let shouldAnimateOnPress: Bool
    let appearance: PaymentSheet.Appearance
    typealias DidTapClosure = (RowButton) -> Void
    let didTap: DidTapClosure
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

    init(appearance: PaymentSheet.Appearance, imageView: UIImageView, text: String, subtext: String? = nil, rightAccessoryView: UIView? = nil, shouldAnimateOnPress: Bool = false, didTap: @escaping DidTapClosure) {
        self.appearance = appearance
        self.shouldAnimateOnPress = shouldAnimateOnPress
        self.didTap = didTap
        self.shadowRoundedRect = ShadowedRoundedRectangle(appearance: appearance)
        self.imageView = imageView
        self.label = Self.makeVerticalRowButtonLabel(text: text, appearance: appearance)
        if let subtext {
            let sublabel = UILabel()
            sublabel.font = appearance.scaledFont(for: appearance.font.base.regular, style: .caption1, maximumPointSize: 20)
            sublabel.numberOfLines = 1
            sublabel.adjustsFontSizeToFitWidth = true
            sublabel.adjustsFontForContentSizeCategory = true
            sublabel.text = subtext
            sublabel.textColor = appearance.colors.componentPlaceholderText
            self.sublabel = sublabel
        } else {
            self.sublabel = nil
        }
        super.init(frame: .zero)

        // Label and sublabel
        label.isAccessibilityElement = false
        let labelsStackView = UIStackView(arrangedSubviews: [
            label, sublabel,
        ].compactMap { $0 })
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

        // Add tap gesture
        shadowRoundedRect.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTap)))

        // Add long press gesture if we should animate on press
        if shouldAnimateOnPress {
            let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPressGesture(gesture:)))
            longPressGesture.minimumPressDuration = 0.2
            longPressGesture.delegate = self
            shadowRoundedRect.addGestureRecognizer(longPressGesture)
        }

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

#if !canImport(CompositorServices)
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        // Update the height so that RowButtons heights w/o subtext match those with subtext
        heightConstraint?.isActive = false
        heightConstraint = heightAnchor.constraint(equalToConstant: Self.calculateTallestHeight(appearance: appearance))
        heightConstraint?.isActive = true
        super.traitCollectionDidChange(previousTraitCollection)
    }
#endif

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

    // MARK: Tap handling
    @objc private func handleTap() {
        guard isEnabled else { return }
        if shouldAnimateOnPress {
            // Fade the text and icon out and back in
            setContentViewAlpha(0.5)
            UIView.animate(withDuration: 0.2, delay: 0.1) { [self] in
                setContentViewAlpha(1.0)
            }
        }
        self.didTap(self)
    }

    /// Sets icon, text, and sublabel alpha
    func setContentViewAlpha(_ alpha: CGFloat) {
        [imageView, label, sublabel].compactMap { $0 }.forEach {
            $0.alpha = alpha
        }
    }

    @objc private func handleLongPressGesture(gesture: UILongPressGestureRecognizer) {
        // Fade the text and icon out while the button is long pressed
        switch gesture.state {
        case .began:
            setContentViewAlpha(0.5)
        default:
            setContentViewAlpha(1.0)
        }
    }
}

// MARK: - EventHandler
extension RowButton: EventHandler {
    func handleEvent(_ event: STPEvent) {
        switch event {
        case .shouldEnableUserInteraction:
            label.alpha = 1
            sublabel?.alpha = 1
            imageView.alpha = 1
        case .shouldDisableUserInteraction:
            label.alpha = 0.5
            sublabel?.alpha = 0.5
            imageView.alpha = 0.5
        default:
            break
        }
    }
}

// MARK: - UIGestureRecognizerDelegate
extension RowButton: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // Without this, the long press prevents you from scrolling or the tap gesture from triggering.
        true
    }
}

// MARK: - Helpers
extension RowButton {
    static func calculateTallestHeight(appearance: PaymentSheet.Appearance) -> CGFloat {
        let imageView = UIImageView(image: Image.link_icon.makeImage())
        imageView.contentMode = .scaleAspectFit
        let tallestRowButton = RowButton(appearance: appearance, imageView: imageView, text: "Dummy text", subtext: "Dummy subtext") { _ in }
        let size = tallestRowButton.systemLayoutSizeFitting(.init(width: 320, height: UIView.noIntrinsicMetric))
        return size.height
    }

    static func makeVerticalRowButtonLabel(text: String, appearance: PaymentSheet.Appearance) -> UILabel {
        let label = UILabel()
        label.font = appearance.scaledFont(for: appearance.font.base.medium, style: .subheadline, maximumPointSize: 25)
        label.adjustsFontSizeToFitWidth = true
        label.adjustsFontForContentSizeCategory = true
        label.text = text
        label.numberOfLines = 1
        label.textColor = appearance.colors.componentText
        return label
    }

    static func makeForPaymentMethodType(paymentMethodType: PaymentSheet.PaymentMethodType, subtitle: String? = nil, savedPaymentMethodType: STPPaymentMethodType?, appearance: PaymentSheet.Appearance, shouldAnimateOnPress: Bool, didTap: @escaping DidTapClosure) -> RowButton {
        let imageView = PaymentMethodTypeImageView(paymentMethodType: paymentMethodType, backgroundColor: appearance.colors.componentBackground)
        imageView.contentMode = .scaleAspectFit
        // Special case "New card" vs "Card" title
        let text: String = {
            if savedPaymentMethodType == .card && paymentMethodType == .stripe(.card) {
                return .Localized.new_card
            }
            return paymentMethodType.displayName
        }()
        return RowButton(appearance: appearance, imageView: imageView, text: text, subtext: subtitle, shouldAnimateOnPress: shouldAnimateOnPress, didTap: didTap)
    }

    static func makeForApplePay(appearance: PaymentSheet.Appearance, didTap: @escaping DidTapClosure) -> RowButton {
        // Apple Pay logo has built-in padding and ends up looking too small; compensate with insets
        let applePayLogo = Image.apple_pay_mark.makeImage().withAlignmentRectInsets(UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8))
        let imageView = UIImageView(image: applePayLogo)
        imageView.contentMode = .scaleAspectFit
        return RowButton(appearance: appearance, imageView: imageView, text: String.Localized.apple_pay, didTap: didTap)
    }

    static func makeForLink(appearance: PaymentSheet.Appearance, didTap: @escaping DidTapClosure) -> RowButton {
        let imageView = UIImageView(image: Image.link_icon.makeImage())
        imageView.contentMode = .scaleAspectFit
        let button = RowButton(appearance: appearance, imageView: imageView, text: STPPaymentMethodType.link.displayName, subtext: .Localized.link_subtitle_text, didTap: didTap)
        button.shadowRoundedRect.accessibilityLabel = String.Localized.pay_with_link
        return button
    }

    static func makeForSavedPaymentMethod(paymentMethod: STPPaymentMethod, appearance: PaymentSheet.Appearance, rightAccessoryView: UIView? = nil, didTap: @escaping DidTapClosure) -> RowButton {
        let imageView = UIImageView(image: paymentMethod.makeSavedPaymentMethodRowImage())
        imageView.contentMode = .scaleAspectFit
        let button = RowButton(appearance: appearance, imageView: imageView, text: paymentMethod.paymentSheetLabel, rightAccessoryView: rightAccessoryView, didTap: didTap)
        button.shadowRoundedRect.accessibilityLabel = paymentMethod.paymentSheetAccessibilityLabel
        return button
    }
}
