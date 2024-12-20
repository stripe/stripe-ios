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

/// A selectable button with various display styles used in vertical mode and embedded to display payment methods.
class RowButton: UIView {
    private let shadowRoundedRect: ShadowedRoundedRectangle
    private lazy var radioButton: RadioButton? = {
        guard isEmbedded, appearance.embeddedPaymentElement.row.style == .flatWithRadio else { return nil }
        return RadioButton(appearance: appearance) { [weak self] in
            guard let self else { return }
            self.didTap(self)
        }
    }()
    private lazy var checkmarkImageView: UIImageView? = {
        guard isFlatWithCheckmarkStyle else { return nil }
        let checkmarkImageView = UIImageView(image: Image.embedded_check.makeImage(template: true))
        checkmarkImageView.tintColor = appearance.embeddedPaymentElement.row.flat.checkmark.color ?? appearance.colors.primary
        checkmarkImageView.contentMode = .scaleAspectFit
        checkmarkImageView.isHidden = true
        return checkmarkImageView
    }()
    let imageView: UIImageView
    let label: UILabel
    let sublabel: UILabel?
    let defaultBadge: UILabel?
    let rightAccessoryView: UIView?
    let promoBadge: PromoBadgeView?
    private var promoBadgeConstraintToCheckmark: NSLayoutConstraint?
    let shouldAnimateOnPress: Bool
    let appearance: PaymentSheet.Appearance
    typealias DidTapClosure = (RowButton) -> Void
    let didTap: DidTapClosure
    // When true, this `RowButton` is being used in the embedded payment element, otherwise it is in use in PaymentSheet
    let isEmbedded: Bool
    var isSelected: Bool = false {
        didSet {
            shadowRoundedRect.isSelected = isSelected
            radioButton?.isOn = isSelected
            checkmarkImageView?.isHidden = !isSelected
            updateAccessibilityTraits()
            updateDefaultBadgeFont()
            if isFlatWithCheckmarkStyle {
                alignBadgeAndCheckmark()
            }
        }
    }
    /// When enabled the `didTap` closure will be called when the button is tapped. When false the `didTap` closure will not be called on taps
    var isEnabled: Bool = true {
        didSet {
            updateAccessibilityTraits()
        }
    }
    var isFlatWithCheckmarkStyle: Bool {
        return appearance.embeddedPaymentElement.row.style == .flatWithCheckmark && isEmbedded
    }
    var heightConstraint: NSLayoutConstraint?

    
    private var selectedDefaultBadgeFont: UIFont {
        return appearance.scaledFont(for: appearance.font.base.medium, style: .caption1, maximumPointSize: 20)
    }

    private var defaultBadgeFont: UIFont {
        return appearance.scaledFont(for: appearance.font.base.regular, style: .caption1, maximumPointSize: 20)
    }

    init(
        appearance: PaymentSheet.Appearance,
        originalCornerRadius: CGFloat? = nil,
        imageView: UIImageView,
        text: String,
        subtext: String? = nil,
        badgeText: String? = nil,
        promoText: String? = nil,
        rightAccessoryView: UIView? = nil,
        shouldAnimateOnPress: Bool = false,
        isEmbedded: Bool = false,
        didTap: @escaping DidTapClosure
    ) {
        self.appearance = appearance
        self.shouldAnimateOnPress = true
        self.didTap = didTap
        self.shadowRoundedRect = ShadowedRoundedRectangle(appearance: appearance)
        self.imageView = imageView
        self.label = Self.makeVerticalRowButtonLabel(text: text, appearance: appearance)
        self.isEmbedded = isEmbedded
        self.rightAccessoryView = rightAccessoryView
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
        if let badgeText {
            let defaultBadge = UILabel()
            defaultBadge.font = appearance.scaledFont(for: appearance.font.base.medium, style: .caption1, maximumPointSize: 20)
            defaultBadge.textColor = appearance.colors.textSecondary
            defaultBadge.adjustsFontForContentSizeCategory = true
            defaultBadge.text = badgeText
            self.defaultBadge = defaultBadge
        } else {
            self.defaultBadge = nil
        }
        if let promoText {
            self.promoBadge = PromoBadgeView(
                appearance: appearance,
                cornerRadius: originalCornerRadius,
                tinyMode: false,
                text: promoText
            )
        } else {
            self.promoBadge = nil
        }
        super.init(frame: .zero)

        // Label and sublabel
        label.isAccessibilityElement = false
        let labelsStackView = UIStackView(arrangedSubviews: [
            label, sublabel, isFlatWithCheckmarkStyle ? rightAccessoryView : nil // add accessory view below labels if in checkmark style
        ].compactMap { $0 })
        labelsStackView.axis = .vertical
        labelsStackView.alignment = .leading

        addAndPinSubview(shadowRoundedRect)

        if let rightAccessoryView, !isFlatWithCheckmarkStyle {
            let rightAccessoryViewPadding: CGFloat = {
                guard isEmbedded else {
                    return -12
                }
                
                switch appearance.embeddedPaymentElement.row.style {
                case .flatWithRadio, .flatWithCheckmark:
                    return 0
                case .floatingButton:
                    return -12
                }
            }()
            rightAccessoryView.translatesAutoresizingMaskIntoConstraints = false
            addSubview(rightAccessoryView)
            NSLayoutConstraint.activate([
                rightAccessoryView.topAnchor.constraint(equalTo: topAnchor),
                rightAccessoryView.bottomAnchor.constraint(equalTo: bottomAnchor),
                rightAccessoryView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: rightAccessoryViewPadding),
            ])
        }
        
        if let checkmarkImageView {
            checkmarkImageView.translatesAutoresizingMaskIntoConstraints = false
            addSubview(checkmarkImageView)
            NSLayoutConstraint.activate([
                checkmarkImageView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
                checkmarkImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
                checkmarkImageView.widthAnchor.constraint(equalToConstant: 16),
                checkmarkImageView.heightAnchor.constraint(equalToConstant: 16),
            ])
        }
        
        if let promoBadge {
            let promoBadgePadding: CGFloat = {
                guard isEmbedded else {
                    return -12
                }
                
                switch appearance.embeddedPaymentElement.row.style {
                case .flatWithRadio:
                    return 0
                case .flatWithCheckmark, .floatingButton:
                    return -12
                }
            }()
            promoBadge.translatesAutoresizingMaskIntoConstraints = false
            addSubview(promoBadge)
            NSLayoutConstraint.activate([
                promoBadge.centerYAnchor.constraint(equalTo: centerYAnchor),
                promoBadge.trailingAnchor.constraint(equalTo: trailingAnchor, constant: promoBadgePadding),
            ])
            
            if isFlatWithCheckmarkStyle {
                alignBadgeAndCheckmark()
            }
        }

        for view in [radioButton, imageView, labelsStackView, defaultBadge].compactMap({ $0 }) {
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
            heightConstraint = heightAnchor.constraint(equalToConstant: Self.calculateTallestHeight(appearance: appearance,
                                                                                                    isEmbedded: isEmbedded,
                                                                                                    isFlatWithCheckmarkStyle: isFlatWithCheckmarkStyle,
                                                                                                    accessoryView: rightAccessoryView))
            heightConstraint?.isActive = true
        }
        
        let insets = isEmbedded ? appearance.embeddedPaymentElement.row.additionalInsets : 4
        
        var imageViewConstraints = [
            imageView.leadingAnchor.constraint(equalTo: radioButton?.trailingAnchor ?? leadingAnchor, constant: 12),
            imageView.topAnchor.constraint(greaterThanOrEqualTo: topAnchor, constant: 10 + insets),
            imageView.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -10 - insets),
            imageView.heightAnchor.constraint(equalToConstant: 20),
            imageView.widthAnchor.constraint(equalToConstant: 24),
        ]

        let isSavedPMRow = rightAccessoryView != nil
        if isFlatWithCheckmarkStyle, isSavedPMRow {
            labelsStackView.setCustomSpacing(8, after: label)
            imageViewConstraints.append(imageView.centerYAnchor.constraint(equalTo: label.centerYAnchor))
        } else {
            imageViewConstraints.append(imageView.centerYAnchor.constraint(equalTo: centerYAnchor))
        }

        NSLayoutConstraint.activate(imageViewConstraints)
        
        let labelTrailingConstant = isFlatWithCheckmarkStyle ? checkmarkImageView?.leadingAnchor ?? trailingAnchor : rightAccessoryView?.leadingAnchor ?? trailingAnchor
        NSLayoutConstraint.activate([
            radioButton?.leadingAnchor.constraint(equalTo: leadingAnchor),
            radioButton?.centerYAnchor.constraint(equalTo: centerYAnchor),
            radioButton?.heightAnchor.constraint(equalToConstant: 18),
            radioButton?.widthAnchor.constraint(equalToConstant: 18),

            labelsStackView.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 12),
            labelsStackView.trailingAnchor.constraint(equalTo: promoBadge?.leadingAnchor ?? labelTrailingConstant, constant: -12),
            labelsStackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            labelsStackView.topAnchor.constraint(greaterThanOrEqualTo: topAnchor, constant: insets),
            labelsStackView.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -insets),

            defaultBadge?.leadingAnchor.constraint(equalTo: label.trailingAnchor, constant: 8),
            defaultBadge?.centerYAnchor.constraint(equalTo: centerYAnchor),
            
            imageViewBottomConstraint,
            imageViewTopConstraint,
        ].compactMap({ $0 }))

        // Add tap gesture
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        gestureRecognizer.delegate = self
        shadowRoundedRect.addGestureRecognizer(gestureRecognizer)

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
    
    private func alignBadgeAndCheckmark() {
        guard let promoBadge, let checkmarkImageView else {
            return
        }
        
        if promoBadgeConstraintToCheckmark == nil {
            promoBadgeConstraintToCheckmark = promoBadge.trailingAnchor.constraint(equalTo: checkmarkImageView.leadingAnchor, constant: -12)
        }
        
        promoBadgeConstraintToCheckmark?.isActive = isSelected
    }

    private func updateDefaultBadgeFont() {
        guard let defaultBadge else {
            return
        }
        defaultBadge.font = isSelected ? selectedDefaultBadgeFont : defaultBadgeFont
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

#if !canImport(CompositorServices)
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        // Update the height so that RowButtons heights w/o subtext match those with subtext
        heightConstraint?.isActive = false
        heightConstraint = heightAnchor.constraint(equalToConstant: Self.calculateTallestHeight(appearance: appearance,
                                                                                                isEmbedded: isEmbedded,
                                                                                                isFlatWithCheckmarkStyle: isFlatWithCheckmarkStyle,
                                                                                                accessoryView: rightAccessoryView))
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
        [imageView, label, sublabel, defaultBadge, promoBadge].compactMap { $0 }.forEach {
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
        let views = [label, sublabel, imageView, promoBadge].compactMap { $0.self }
        
        switch event {
        case .shouldEnableUserInteraction:
            views.forEach { $0.alpha = 1 }
        case .shouldDisableUserInteraction:
            views.forEach { $0.alpha = 0.5 }
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
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if let accessoryView = rightAccessoryView as? RightAccessoryButton {
            let locationInAccessoryView = touch.location(in: accessoryView)
            if accessoryView.bounds.contains(locationInAccessoryView) {
                accessoryView.handleTap()
                return false
            }
        }
        
        return true
    }
}

// MARK: - Helpers
extension RowButton {
    static func calculateTallestHeight(appearance: PaymentSheet.Appearance, isEmbedded: Bool, isFlatWithCheckmarkStyle: Bool = false, accessoryView: UIView? = nil) -> CGFloat {
        let imageView = UIImageView(image: Image.link_icon.makeImage())
        imageView.contentMode = .scaleAspectFit
        let tallestRowButton = RowButton(appearance: appearance, imageView: imageView, text: "Dummy text", subtext: "Dummy subtext", isEmbedded: isEmbedded) { _ in }
        let size = tallestRowButton.systemLayoutSizeFitting(.init(width: 320, height: UIView.noIntrinsicMetric))
        
        // Check if in .flatWithCheck style and if rightAccessoryView exists, if so account for the Edit button being below the labels
        // This additional height should not be reflected by other rows
        if isFlatWithCheckmarkStyle, let accessoryView {
            let accessoryViewHeight = accessoryView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
            return size.height + accessoryViewHeight + 4 // bake in some extra padding to match figma
        }
        
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

    static func makeForPaymentMethodType(
        paymentMethodType: PaymentSheet.PaymentMethodType,
        subtitle: String? = nil,
        hasSavedCard: Bool,
        rightAccessoryView: UIView? = nil,
        promoText: String? = nil,
        appearance: PaymentSheet.Appearance,
        originalCornerRadius: CGFloat? = nil,
        shouldAnimateOnPress: Bool,
        isEmbedded: Bool = false,
        didTap: @escaping DidTapClosure
    ) -> RowButton {
        let imageView = PaymentMethodTypeImageView(paymentMethodType: paymentMethodType, backgroundColor: appearance.colors.componentBackground)
        imageView.contentMode = .scaleAspectFit
        // Special case "New card" vs "Card" title
        let text: String = {
            if hasSavedCard && paymentMethodType == .stripe(.card) {
                return .Localized.new_card
            }
            return paymentMethodType.displayName
        }()
        return RowButton(appearance: appearance, originalCornerRadius: originalCornerRadius, imageView: imageView, text: text, subtext: subtitle, promoText: promoText, rightAccessoryView: rightAccessoryView, shouldAnimateOnPress: shouldAnimateOnPress, isEmbedded: isEmbedded, didTap: didTap)
    }

    static func makeForApplePay(appearance: PaymentSheet.Appearance, isEmbedded: Bool = false, didTap: @escaping DidTapClosure) -> RowButton {
        // Apple Pay logo has built-in padding and ends up looking too small; compensate with insets
        let applePayLogo = Image.apple_pay_mark.makeImage().withAlignmentRectInsets(UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8))
        let imageView = UIImageView(image: applePayLogo)
        imageView.contentMode = .scaleAspectFit
        return RowButton(appearance: appearance, imageView: imageView, text: String.Localized.apple_pay, isEmbedded: isEmbedded, didTap: didTap)
    }

    static func makeForLink(appearance: PaymentSheet.Appearance, isEmbedded: Bool = false, didTap: @escaping DidTapClosure) -> RowButton {
        let imageView = UIImageView(image: Image.link_icon.makeImage())
        imageView.contentMode = .scaleAspectFit
        let button = RowButton(appearance: appearance, imageView: imageView, text: STPPaymentMethodType.link.displayName, subtext: .Localized.link_subtitle_text, isEmbedded: isEmbedded, didTap: didTap)
        button.shadowRoundedRect.accessibilityLabel = String.Localized.pay_with_link
        return button
    }

    static func makeForSavedPaymentMethod(paymentMethod: STPPaymentMethod, appearance: PaymentSheet.Appearance, subtext: String? = nil, badgeText: String? = nil, rightAccessoryView: UIView? = nil, isEmbedded: Bool = false, didTap: @escaping DidTapClosure) -> RowButton {
        let imageView = UIImageView(image: paymentMethod.makeSavedPaymentMethodRowImage())
        imageView.contentMode = .scaleAspectFit
        let button = RowButton(appearance: appearance, imageView: imageView, text: paymentMethod.paymentSheetLabel, subtext: subtext, badgeText: badgeText, rightAccessoryView: rightAccessoryView, isEmbedded: isEmbedded, didTap: didTap)
        button.shadowRoundedRect.accessibilityLabel = paymentMethod.paymentSheetAccessibilityLabel
        return button
    }
}
