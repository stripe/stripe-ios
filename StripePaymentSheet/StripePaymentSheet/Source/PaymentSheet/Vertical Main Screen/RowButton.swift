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
    let type: RowButtonType
    private let shadowRoundedRect: ShadowedRoundedRectangle
    let imageView: UIImageView
    let label: UILabel
    let sublabel: UILabel
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
            content?.isSelected = isSelected
            updateAccessibilityTraits()
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

    // TODO(porter) Make this not optional once we have all the styles implemented
    private(set) var content: RowButtonContent?

    init(
        appearance: PaymentSheet.Appearance,
        type: RowButtonType,
        imageView: UIImageView,
        text: String,
        subtext: String? = nil,
        badgeText: String? = nil,
        promoBadge: PromoBadgeView? = nil,
        rightAccessoryView: UIView? = nil,
        shouldAnimateOnPress: Bool = false,
        isEmbedded: Bool = false,
        didTap: @escaping DidTapClosure
    ) {
        self.appearance = appearance
        self.type = type
        self.shouldAnimateOnPress = shouldAnimateOnPress
        self.didTap = didTap
        self.shadowRoundedRect = ShadowedRoundedRectangle(appearance: appearance)
        self.imageView = imageView
        self.label = Self.makeRowButtonLabel(text: text, appearance: appearance)
        self.isEmbedded = isEmbedded
        self.rightAccessoryView = rightAccessoryView
        self.sublabel = Self.makeRowButtonSublabel(text: subtext, appearance: appearance)
        self.defaultBadge = Self.makeRowButtonDefaultBadgeLabel(badgeText: badgeText, appearance: appearance)
        self.promoBadge = promoBadge
        super.init(frame: .zero)

        addAndPinSubview(shadowRoundedRect)

        setupTapGestures()

        // Accessibility
        // Subviews of an accessibility element are ignored
        isAccessibilityElement = false
        accessibilityIdentifier = text // Just for test purposes
        accessibilityElements = [shadowRoundedRect, rightAccessoryView].compactMap { $0 }
        shadowRoundedRect.accessibilityIdentifier = text
        shadowRoundedRect.accessibilityLabel = text
        shadowRoundedRect.isAccessibilityElement = true
        updateAccessibilityTraits()

        // Early-exit for flatWithRadio
        if isEmbedded && appearance.embeddedPaymentElement.row.style == .flatWithRadio {
            let rowButtonFlatWithRadioView = RowButtonFlatWithRadioView(
                appearance: appearance,
                imageView: imageView,
                text: text,
                subtext: subtext,
                rightAccessoryView: rightAccessoryView,
                defaultBadgeText: badgeText,
                promoBadge: promoBadge)

            addAndPinSubview(rowButtonFlatWithRadioView)
            self.content = rowButtonFlatWithRadioView
            makeSameHeightAsOtherRowButtonsIfNecessary()
            return // Skip the rest of the complicated layout
        }

        if !isEmbedded || appearance.embeddedPaymentElement.row.style == .floatingButton {
            let insets = isEmbedded ? appearance.embeddedPaymentElement.row.additionalInsets : 4
            let rowButtonFloating = RowButtonFloating(
                appearance: appearance,
                imageView: imageView,
                text: text,
                subtext: subtext,
                rightAccessoryView: rightAccessoryView,
                defaultBadgeText: badgeText,
                promoBadge: promoBadge,
                insets: insets)

            addAndPinSubview(rowButtonFloating)
            self.content = rowButtonFloating
            makeSameHeightAsOtherRowButtonsIfNecessary()
            return // Skip the rest of the complicated layout
        }
        
        if appearance.embeddedPaymentElement.row.style == .flatWithCheckmark {
            let rowButtonFlatWithCheckmarkView = RowButtonFlatWithCheckmark(
                appearance: appearance,
                imageView: imageView,
                text: text,
                subtext: subtext,
                bottomAccessoryView: rightAccessoryView,
                defaultBadgeText: badgeText,
                promoBadge: promoBadge)

            addAndPinSubview(rowButtonFlatWithCheckmarkView)
            self.content = rowButtonFlatWithCheckmarkView
            makeSameHeightAsOtherRowButtonsIfNecessary()
            return // Skip the rest of the complicated layout
        }
    }

    private func setupTapGestures() {
        // Add tap gesture
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        gestureRecognizer.delegate = self
        addGestureRecognizer(gestureRecognizer)

        // Add long press gesture if we should animate on press
        if shouldAnimateOnPress {
            let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPressGesture(gesture:)))
            longPressGesture.minimumPressDuration = 0.2
            longPressGesture.delegate = self
            addGestureRecognizer(longPressGesture)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

#if !canImport(CompositorServices)
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        // If the font size changes, make this RowButton the same height as the tallest variant if necessary
        heightConstraint?.isActive = false
        makeSameHeightAsOtherRowButtonsIfNecessary()
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
    @objc func handleTap() {
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

        content?.subviews.map { $0 }.forEach {
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

    func makeSameHeightAsOtherRowButtonsIfNecessary() {
        // To make all RowButtons the same height, set our height to the tallest variant (a RowButton w/ text and subtext)
        // Don't do this if we are flat_with_checkmark style and have an accessory view - this row button is allowed to be taller than the rest
        let isDisplayingRightAccessoryView = rightAccessoryView?.isHidden == false
        if isFlatWithCheckmarkStyle && isDisplayingRightAccessoryView {
            heightConstraint?.isActive = false
            return
        }
        // Don't do this if we *are* the tallest variant; otherwise we'll infinite loop!
        let isSublabelTextEmpty = sublabel.text?.isEmpty ?? !(content?.hasSubtext ?? true)
        guard isSublabelTextEmpty else {
            heightConstraint?.isActive = false
            return
        }
        heightConstraint = heightAnchor.constraint(equalToConstant: Self.calculateTallestHeight(appearance: appearance, isEmbedded: isEmbedded))
        heightConstraint?.isActive = true
    }
}

// MARK: - EventHandler
extension RowButton: EventHandler {
    func handleEvent(_ event: STPEvent) {
        switch event {
        case .shouldEnableUserInteraction:
            setContentViewAlpha(1.0)
        case .shouldDisableUserInteraction:
            setContentViewAlpha(0.5)
        default:
            break
        }
    }
}

// MARK: - UIGestureRecognizerDelegate
extension RowButton: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // Without this, the long press prevents you from scrolling or our tap/pan gesture from triggering together.
        return otherGestureRecognizer is UIPanGestureRecognizer || (gestureRecognizers?.contains(otherGestureRecognizer) ?? false)
    }

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        // If the scroll view’s pan gesture begins, we want to fail the button’s tap,
        // so the user can scroll without accidentally tapping.
        if otherGestureRecognizer is UIPanGestureRecognizer {
            return true
        }

        return false
    }
}

// MARK: - Helpers
extension RowButton {
    static func calculateTallestHeight(appearance: PaymentSheet.Appearance, isEmbedded: Bool) -> CGFloat {
        let imageView = UIImageView(image: Image.link_icon.makeImage())
        imageView.contentMode = .scaleAspectFit
        let tallestRowButton = RowButton(appearance: appearance, type: .new(paymentMethodType: .stripe(.afterpayClearpay)), imageView: imageView, text: "Dummy text", subtext: "Dummy subtext", isEmbedded: isEmbedded) { _ in }
        let size = tallestRowButton.systemLayoutSizeFitting(.init(width: 320, height: UIView.noIntrinsicMetric))
        return size.height
    }

    static func makeRowButtonLabel(text: String, appearance: PaymentSheet.Appearance) -> UILabel {
        let label = UILabel()
        label.font = appearance.scaledFont(for: appearance.font.base.medium, style: .subheadline, maximumPointSize: 25)
        label.adjustsFontSizeToFitWidth = true
        label.adjustsFontForContentSizeCategory = true
        label.text = text
        label.numberOfLines = 1
        label.textColor = appearance.colors.componentText
        return label
    }

    static func makeRowButtonSublabel(text: String?, appearance: PaymentSheet.Appearance) -> UILabel {
        let sublabel = UILabel()
        sublabel.font = appearance.scaledFont(for: appearance.font.base.regular, style: .caption1, maximumPointSize: 20)
        sublabel.numberOfLines = 1
        sublabel.adjustsFontSizeToFitWidth = true
        sublabel.adjustsFontForContentSizeCategory = true
        sublabel.text = text
        sublabel.textColor = appearance.colors.componentPlaceholderText
        sublabel.isHidden = text?.isEmpty ?? true
        return sublabel
    }

    static func makeRowButtonDefaultBadgeLabel(badgeText: String?, appearance: PaymentSheet.Appearance) -> UILabel? {
        guard let badgeText else { return nil }
        let defaultBadge = UILabel()
        defaultBadge.font = appearance.scaledFont(for: appearance.font.base.medium, style: .caption1, maximumPointSize: 20)
        defaultBadge.textColor = appearance.colors.textSecondary
        defaultBadge.adjustsFontForContentSizeCategory = true
        defaultBadge.text = badgeText
        return defaultBadge
    }

    static func makeForPaymentMethodType(
        paymentMethodType: PaymentSheet.PaymentMethodType,
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
        let subtext: String? = {
            switch paymentMethodType {
            case .stripe(.klarna):
                return String.Localized.buy_now_or_pay_later_with_klarna
            case .stripe(.afterpayClearpay):
                if AfterpayPriceBreakdownView.shouldUseClearpayBrand(for: Locale.current) {
                    return String.Localized.buy_now_or_pay_later_with_clearpay
                } else {
                    return String.Localized.buy_now_or_pay_later_with_afterpay
                }
            case .stripe(.affirm):
                return String.Localized.pay_over_time_with_affirm
            default:
                return nil
            }
        }()

        let promoBadge: PromoBadgeView? = {
            guard let promoText else { return nil }
            return PromoBadgeView(
                appearance: appearance,
                cornerRadius: originalCornerRadius,
                tinyMode: false,
                text: promoText
            )
        }()

        return RowButton(
            appearance: appearance,
            type: .new(paymentMethodType: paymentMethodType),
            imageView: imageView,
            text: text,
            subtext: subtext,
            promoBadge: promoBadge,
            rightAccessoryView: rightAccessoryView,
            shouldAnimateOnPress: shouldAnimateOnPress,
            isEmbedded: isEmbedded,
            didTap: didTap
        )
    }

    static func makeForApplePay(appearance: PaymentSheet.Appearance, isEmbedded: Bool = false, didTap: @escaping DidTapClosure) -> RowButton {
        // Apple Pay logo has built-in padding and ends up looking too small; compensate with insets
        let applePayLogo = Image.apple_pay_mark.makeImage().withAlignmentRectInsets(UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8))
        let imageView = UIImageView(image: applePayLogo)
        imageView.contentMode = .scaleAspectFit
        return RowButton(appearance: appearance, type: .applePay, imageView: imageView, text: String.Localized.apple_pay, isEmbedded: isEmbedded, didTap: didTap)
    }

    static func makeForLink(appearance: PaymentSheet.Appearance, isEmbedded: Bool = false, didTap: @escaping DidTapClosure) -> RowButton {
        let imageView = UIImageView(image: Image.link_icon.makeImage())
        imageView.contentMode = .scaleAspectFit
        let button = RowButton(appearance: appearance, type: .link, imageView: imageView, text: STPPaymentMethodType.link.displayName, subtext: .Localized.link_subtitle_text, isEmbedded: isEmbedded, didTap: didTap)
        button.shadowRoundedRect.accessibilityLabel = String.Localized.pay_with_link
        return button
    }

    static func makeForSavedPaymentMethod(paymentMethod: STPPaymentMethod, appearance: PaymentSheet.Appearance, subtext: String? = nil, badgeText: String? = nil, rightAccessoryView: UIView? = nil, isEmbedded: Bool = false, didTap: @escaping DidTapClosure) -> RowButton {
        let imageView = UIImageView(image: paymentMethod.makeSavedPaymentMethodRowImage())
        imageView.contentMode = .scaleAspectFit
        let button = RowButton(appearance: appearance, type: .saved(paymentMethod: paymentMethod), imageView: imageView, text: paymentMethod.paymentSheetLabel, subtext: subtext, badgeText: badgeText, rightAccessoryView: rightAccessoryView, isEmbedded: isEmbedded, didTap: didTap)
        button.shadowRoundedRect.accessibilityLabel = paymentMethod.paymentSheetAccessibilityLabel
        return button
    }
}

// MARK: - RowButtonType
enum RowButtonType: Equatable {
    case new(paymentMethodType: PaymentSheet.PaymentMethodType)
    case saved(paymentMethod: STPPaymentMethod)
    case applePay
    case link

    static func == (lhs: RowButtonType, rhs: RowButtonType) -> Bool {
        switch (lhs, rhs) {
        case (.link, .link):
            return true
        case (.applePay, .applePay):
            return true
        case let (.new(lhsPMType), .new(rhsPMType)):
            return lhsPMType == rhsPMType
        case let (.saved(lhsPM), .saved(rhsPM)):
            return lhsPM.stripeId == rhsPM.stripeId && lhsPM.calculateCardBrandToDisplay() == rhsPM.calculateCardBrandToDisplay()
        default:
            return false
        }
    }

    var isSaved: Bool {
        switch self {
        case .saved:
            return true
        default:
            return false
        }
    }

    var analyticsIdentifier: String {
        switch self {
        case .applePay:
            return "apple_pay"
        case .link:
            return "link"
        case .saved:
            return "saved"
        case .new(paymentMethodType: let type):
            return type.identifier
        }
    }

    var savedPaymentMethod: STPPaymentMethod? {
        switch self {
        case .applePay, .link, .new:
            return nil
        case .saved(let paymentMethod):
            return paymentMethod
        }
    }

    var paymentMethodType: PaymentSheet.PaymentMethodType? {
        switch self {
        case .new(let paymentMethodType):
            return paymentMethodType
        case .saved(let paymentMethod):
            return .stripe(paymentMethod.type)
        case .applePay, .link:
            return nil
        }
    }
}

extension PaymentSheet.Appearance {
    var selectedDefaultBadgeFont: UIFont {
        return scaledFont(for: font.base.medium, style: .caption1, maximumPointSize: 20)
    }

    var defaultBadgeFont: UIFont {
        return scaledFont(for: font.base.regular, style: .caption1, maximumPointSize: 20)
    }
}
