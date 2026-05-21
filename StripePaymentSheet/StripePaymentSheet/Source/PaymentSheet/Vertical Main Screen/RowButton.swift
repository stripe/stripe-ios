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
/// - Note: This is an 'abstract base class', see its subclasses.
class RowButton: UIView, EventHandler {
    typealias DidTapClosure = (RowButton) -> Void

    // MARK: Subviews

    /// Exists for accessibility reasons to give the RowButton accessible features while keeping the accessory button accessible
    private let accessibilityHelperView = UIView()
    /// Typically the payment method icon or brand image
    let imageView: UIImageView
    /// The main label for the payment method name
    let label: UILabel
    /// The subtitle, e.g. “Pay over time with Affirm”
    var sublabel: SublabelView
    /// For layout convenience: if we have an accessory view on the bottom (e.g. a brand logo, etc.)
    let accessoryView: UIView?
    /// The label indicating if this is the default saved payment method
    let defaultBadgeLabel: UILabel?
    /// The view indicating any incentives associated with this payment method
    let promoBadge: PromoBadgeView?

    // MARK: State

    var isSelected: Bool = false {
        didSet {
            updateSelectedState()
        }
    }
    /// When enabled the `didTap` closure will be called when the button is tapped. When false the `didTap` closure will not be called on taps
    var isEnabled: Bool = true {
        didSet {
            updateAccessibilityTraits()
        }
    }

    var isFlatWithCheckmarkOrChevronStyle: Bool {
        let rowStyle = appearance.embeddedPaymentElement.row.style
        return (rowStyle == .flatWithCheckmark || rowStyle == .flatWithDisclosure) && isEmbedded
    }

    var isDisplayingAccessoryView: Bool {
        guard let accessoryView else {
            return false
        }
        return !accessoryView.isHidden
    }

    var imageViewSize: CGSize {
        if appearance.cardArtEnabled {
            // When card art is enabled, allow images to grow in width to 30px
            return CGSize(width: 30, height: 20)
        } else {
            return CGSize(width: 24, height: 20)
        }
    }

    // MARK: Internal properties

    var heightConstraint: NSLayoutConstraint?
    let type: RowButtonType
    let shouldAnimateOnPress: Bool
    let appearance: PaymentSheet.Appearance
    let didTap: DidTapClosure
    // When true, this `RowButton` is being used in the embedded payment element, otherwise it is in use in PaymentSheet
    let isEmbedded: Bool

    init(
        appearance: PaymentSheet.Appearance,
        type: RowButtonType,
        imageView: UIImageView,
        text: String,
        sublabel: SublabelView,
        badgeText: String? = nil,
        promoBadge: PromoBadgeView? = nil,
        accessoryView: UIView? = nil,
        shouldAnimateOnPress: Bool = false,
        isEmbedded: Bool = false,
        didTap: @escaping DidTapClosure
    ) {
        self.appearance = appearance
        self.type = type
        self.shouldAnimateOnPress = shouldAnimateOnPress
        self.didTap = didTap
        self.isEmbedded = isEmbedded
        self.imageView = imageView
        self.label = RowButton.makeRowButtonLabel(text: text, appearance: appearance, isEmbedded: isEmbedded)
        self.sublabel = sublabel
        self.accessoryView = accessoryView
        self.defaultBadgeLabel = RowButton.makeRowButtonDefaultBadgeLabel(badgeText: badgeText, appearance: appearance)
        self.promoBadge = promoBadge

        super.init(frame: .zero)
        addAndPinSubview(accessibilityHelperView)
        setupUI()
        makeSameHeightAsOtherRowButtonsIfNecessary()

        setupTapGestures()

        // Accessibility
        // Subviews of an accessibility element are ignored
        isAccessibilityElement = false
        accessibilityIdentifier = text // Just for test purposes
        accessibilityElements = [accessibilityHelperView, accessoryView].compactMap { $0 }
        accessibilityHelperView.accessibilityIdentifier = text
        accessibilityHelperView.accessibilityLabel = text
        accessibilityHelperView.isAccessibilityElement = true
        updateAccessibilityTraits()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Overrides

#if !os(visionOS)
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        // If the font size changes, make this RowButton the same height as the tallest variant if necessary
        heightConstraint?.isActive = false
        makeSameHeightAsOtherRowButtonsIfNecessary()
        super.traitCollectionDidChange(previousTraitCollection)
    }
#endif

    // MARK: Private functions

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

    private func updateAccessibilityTraits() {
        var traits: UIAccessibilityTraits = [.button]
        if isSelected {
            traits.insert(.selected)
        }
        if !isEnabled {
            traits.insert(.notEnabled)
        }
        accessibilityHelperView.accessibilityTraits = traits
    }

    // MARK: Overridable functions

    /// Override this function to setup the UI for your RowButton subclass
    func setupUI() {
        stpAssertionFailure("RowButton init not called from subclass, use RowButton.create() instead of RowButton(...).")
    }
    
    func setSublabel(text: String?, animated: Bool = true) {
        sublabel.setSublabel(newText: text, animated: animated)
    }

    func setKeyContent(alpha: CGFloat) {
        [imageView, label, sublabel].compactMap { $0 }.forEach {
            $0.alpha = alpha
        }
    }

    func updateSelectedState() {
        // Default badge font is heavier when the row is selected
        defaultBadgeLabel?.font = isSelected ? appearance.selectedDefaultBadgeFont : appearance.defaultBadgeFont
        updateAccessibilityTraits()
        
        sublabel.updateSelectedState(isSelected)
    }

    // MARK: EventHandler

    // Default implementation reduces alpha on all subviews for disabled state
    func handleEvent(_ event: STPEvent) {
        switch event {
        case .shouldEnableUserInteraction:
            accessibilityHelperView.subviews.forEach { $0.alpha = 1 }
        case .shouldDisableUserInteraction:
            accessibilityHelperView.subviews.forEach { $0.alpha = 0.5 }
        default:
            break
        }
    }

    // MARK: Tap handling

    @objc func handleTap() {
        guard isEnabled else { return }
        if shouldAnimateOnPress {
            // Fade the text and icon out and back in
            setKeyContent(alpha: 0.5)
            UIView.animate(withDuration: 0.2, delay: 0.1) { [self] in
                setKeyContent(alpha: 1.0)
            }
        }
        self.didTap(self)
    }

    @objc private func handleLongPressGesture(gesture: UILongPressGestureRecognizer) {
        // Fade the text and icon out while the button is long pressed
        switch gesture.state {
        case .began:
            setKeyContent(alpha: 0.5)
        default:
            setKeyContent(alpha: 1.0)
        }
    }

    // MARK: Helper

    func makeSameHeightAsOtherRowButtonsIfNecessary() {
        // To make all RowButtons the same height, set our height to the tallest
        // standard variant (a RowButton with text and a plain sublabel).

        // The row button is allowed to be taller than the rest and we don't do this if either:
        //      1. We are flat_with_checkmark or flat_with_chevron style and have an accessory view
        //      2. The sublabel requires extra space (payment method messaging variant)
        if (isFlatWithCheckmarkOrChevronStyle && isDisplayingAccessoryView)
            || sublabel.needsUnlimitedHeight {
            heightConstraint?.isActive = false
            return
        }

        // Don't do this if we *are* the tallest variant; otherwise we'll infinite loop!
        if sublabel.hasText {
            heightConstraint?.isActive = false
            return
        }

        heightConstraint = heightAnchor.constraint(equalToConstant: Self.calculateTallestHeight(appearance: appearance, isEmbedded: isEmbedded))
        heightConstraint?.isActive = true
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
    static func create(appearance: PaymentSheet.Appearance,
                       type: RowButtonType,
                       imageView: UIImageView,
                       text: String,
                       sublabel: SublabelView,
                       badgeText: String? = nil,
                       promoBadge: PromoBadgeView? = nil,
                       accessoryView: UIView? = nil,
                       shouldAnimateOnPress: Bool = false,
                       isEmbedded: Bool = false,
                       didTap: @escaping DidTapClosure) -> RowButton {
        if !isEmbedded {
            return RowButtonFloating(
                appearance: appearance,
                type: type,
                imageView: imageView,
                text: text,
                sublabel: sublabel,
                badgeText: badgeText,
                promoBadge: promoBadge,
                accessoryView: accessoryView,
                shouldAnimateOnPress: shouldAnimateOnPress,
                isEmbedded: isEmbedded,
                didTap: didTap
            )
        }

        switch appearance.embeddedPaymentElement.row.style {
        case .flatWithRadio:
            return RowButtonFlatWithRadioView(
                appearance: appearance,
                type: type,
                imageView: imageView,
                text: text,
                sublabel: sublabel,
                badgeText: badgeText,
                promoBadge: promoBadge,
                accessoryView: accessoryView,
                shouldAnimateOnPress: shouldAnimateOnPress,
                isEmbedded: isEmbedded,
                didTap: didTap
            )
        case .floatingButton:
            return RowButtonFloating(
                appearance: appearance,
                type: type,
                imageView: imageView,
                text: text,
                sublabel: sublabel,
                badgeText: badgeText,
                promoBadge: promoBadge,
                accessoryView: accessoryView,
                shouldAnimateOnPress: shouldAnimateOnPress,
                isEmbedded: isEmbedded,
                didTap: didTap
            )
        case .flatWithCheckmark:
            return RowButtonFlatWithCheckmark(
                appearance: appearance,
                type: type,
                imageView: imageView,
                text: text,
                sublabel: sublabel,
                badgeText: badgeText,
                promoBadge: promoBadge,
                accessoryView: accessoryView,
                shouldAnimateOnPress: shouldAnimateOnPress,
                isEmbedded: isEmbedded,
                didTap: didTap
            )
        case .flatWithDisclosure:
            return RowButtonFlatWithDisclosure(
                appearance: appearance,
                type: type,
                imageView: imageView,
                text: text,
                sublabel: sublabel,
                badgeText: badgeText,
                promoBadge: promoBadge,
                accessoryView: accessoryView,
                shouldAnimateOnPress: shouldAnimateOnPress,
                isEmbedded: isEmbedded,
                didTap: didTap
            )
        }
    }

    static func calculateTallestHeight(appearance: PaymentSheet.Appearance, isEmbedded: Bool) -> CGFloat {
        let imageView = UIImageView(image: Image.link_icon.makeImage())
        imageView.contentMode = .scaleAspectFit
        let plainSublabel = PlainSublabelView(text: "Dummy subtext", appearance: appearance, isEmbedded: isEmbedded)
        let tallestPlainRowButton = RowButton.create(
            appearance: appearance,
            type: .new(paymentMethodType: .stripe(.afterpayClearpay)),
            imageView: imageView,
            text: "Dummy text",
            sublabel: plainSublabel,
            didTap: { _ in }
        )
        let size = tallestPlainRowButton.systemLayoutSizeFitting(.init(width: 320, height: UIView.noIntrinsicMetric))
        return size.height
    }

    static func makeRowButtonLabel(text: String, appearance: PaymentSheet.Appearance, isEmbedded: Bool) -> UILabel {
        let label = UILabel()
        if isEmbedded, let customFont = appearance.embeddedPaymentElement.row.titleFont {
            label.font = customFont
        } else {
            label.font = appearance.scaledFont(for: appearance.font.base.medium, style: .subheadline, maximumPointSize: 25)
        }
        label.adjustsFontSizeToFitWidth = true
        label.adjustsFontForContentSizeCategory = true
        label.text = text
        label.numberOfLines = 1
        let textColor: UIColor = {
            guard isEmbedded else {
                return appearance.colors.componentText
            }

            switch appearance.embeddedPaymentElement.row.style {
            case .flatWithRadio, .flatWithCheckmark, .flatWithDisclosure:
                return appearance.colors.text
            case .floatingButton:
                return appearance.colors.componentText
            }
        }()

        label.textColor = textColor
        return label
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
        currency: String?,
        hasSavedCard: Bool,
        accessoryView: UIView?,
        promoText: String?,
        promotionsHelper: PaymentMethodMessagingPromotionsHelper,
        appearance: PaymentSheet.Appearance,
        originalCornerRadius: CGFloat?,
        shouldAnimateOnPress: Bool,
        isEmbedded: Bool,
        didTap: @escaping DidTapClosure
    ) -> RowButton {
        let imageView = PaymentMethodTypeImageView(paymentMethodType: paymentMethodType,
                                                   contrastMatchingColor: appearance.colors.componentText,
                                                   currency: currency,
                                                   iconStyle: appearance.iconStyle)
        imageView.contentMode = .scaleAspectFit

        // Special case "New card" vs "Card" title
        let text: String = {
            if hasSavedCard && paymentMethodType == .stripe(.card) {
                return .Localized.new_card
            }
            return paymentMethodType.displayName
        }()
        
        let sublabel: SublabelView
        if promotionsHelper.isInTreatmentGroup {
            sublabel = PaymentMethodMessagingSublabelView(
                appearance: appearance,
                paymentMethodType: paymentMethodType,
                promotionsHelper: promotionsHelper
            )
        } else {
            let subtext: String? = {
                switch paymentMethodType {
                case .stripe(.klarna):
                    return String.Localized.buy_now_or_pay_later_with_klarna
                case .stripe(.afterpayClearpay):
                    if AfterpayPriceBreakdownView.shouldUseClearpayBrand(for: currency) {
                        return String.Localized.buy_now_or_pay_later_with_clearpay
                    } else if AfterpayPriceBreakdownView.shouldUseCashAppBrand(for: currency) {
                        return String.Localized.buy_now_or_pay_later_with_cash_app_afterpay
                    } else {
                        return String.Localized.buy_now_or_pay_later_with_afterpay
                    }
                case .stripe(.affirm):
                    return String.Localized.pay_over_time_with_affirm
                case .external(let externalPaymentOption):
                    return externalPaymentOption.displaySubtext
                default:
                    return nil
                }
            }()
            sublabel = PlainSublabelView(text: subtext, appearance: appearance, isEmbedded: isEmbedded)
        }

        let promoBadge: PromoBadgeView? = {
            guard let promoText else { return nil }
            return PromoBadgeView(
                appearance: appearance,
                cornerRadius: originalCornerRadius,
                tinyMode: false,
                text: promoText
            )
        }()

        return RowButton.create(
            appearance: appearance,
            type: .new(paymentMethodType: paymentMethodType),
            imageView: imageView,
            text: text,
            sublabel: sublabel,
            promoBadge: promoBadge,
            accessoryView: accessoryView,
            shouldAnimateOnPress: shouldAnimateOnPress,
            isEmbedded: isEmbedded,
            didTap: didTap
        )
    }

    static func makeForApplePay(appearance: PaymentSheet.Appearance, isEmbedded: Bool = false, didTap: @escaping DidTapClosure) -> RowButton {
        let imageView = UIImageView(image: Image.apple_pay_mark.makeImage())
        imageView.contentMode = .scaleAspectFit
        let sublabel = PlainSublabelView(text: nil, appearance: appearance, isEmbedded: isEmbedded)
        return RowButton.create(
            appearance: appearance,
            type: .applePay,
            imageView: imageView,
            text: String.Localized.apple_pay,
            sublabel: sublabel,
            isEmbedded: isEmbedded,
            didTap: didTap
        )
    }

    static func makeForLink(appearance: PaymentSheet.Appearance, isEmbedded: Bool = false, didTap: @escaping DidTapClosure) -> RowButton {
        let imageView = UIImageView(image: Image.link_icon.makeImage())
        imageView.contentMode = .scaleAspectFit
        var subtext = String.Localized.link_subtitle_text
        if let linkAccount = LinkAccountContext.shared.account, linkAccount.isRegistered {
            subtext = linkAccount.email
        }
        let sublabel = PlainSublabelView(text: subtext, appearance: appearance, isEmbedded: isEmbedded)
        let button = RowButton.create(
            appearance: appearance,
            type: .link,
            imageView: imageView,
            text: STPPaymentMethodType.link.displayName,
            sublabel: sublabel,
            isEmbedded: isEmbedded,
            didTap: didTap
        )
        button.accessibilityHelperView.accessibilityLabel = String.Localized.pay_with_link
        return button
    }

    static func makeForSavedPaymentMethod(paymentMethod: STPPaymentMethod, appearance: PaymentSheet.Appearance, subtext: String? = nil, badgeText: String? = nil, accessoryView: UIView? = nil, isEmbedded: Bool = false, didTap: @escaping DidTapClosure) -> RowButton {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        let savedPaymentMethodRowImage = paymentMethod.makeSavedPaymentMethodRowImage(iconStyle: appearance.iconStyle)
        if appearance.cardArtEnabled {
            imageView.setImage(with: paymentMethod.cardArtCDNURL(cardArtEnabled: appearance.cardArtEnabled),
                               processOnDownloadedImage: { $0.roundedWithBorder(radius: 3) },
                               fallbackImage: savedPaymentMethodRowImage,
                               shimmeringImage: STPImageLibrary.cardBrandChoiceImage())
        } else {
            imageView.image = savedPaymentMethodRowImage
        }
        let text = paymentMethod.isLinkPassthroughMode
            ? STPPaymentMethodType.link.displayName
            : paymentMethod.paymentSheetLabel
        let sublabel = PlainSublabelView(
            text: paymentMethod.linkSpecificSublabel ?? subtext,
            appearance: appearance,
            isEmbedded: isEmbedded
        )

        let button = RowButton.create(
            appearance: appearance,
            type: .saved(paymentMethod: paymentMethod),
            imageView: imageView,
            text: text,
            sublabel: sublabel,
            badgeText: badgeText,
            accessoryView: accessoryView,
            isEmbedded: isEmbedded,
            didTap: didTap
        )
        button.accessibilityHelperView.accessibilityLabel = {
            if let badgeText {
                if let accessibilityLabel = paymentMethod.paymentSheetAccessibilityLabel {
                    return "\(accessibilityLabel), \(badgeText)"
                } else {
                    return "\(badgeText)"
                }
            }
            return paymentMethod.paymentSheetAccessibilityLabel
        }()
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

private extension STPPaymentMethod {

    var linkSpecificSublabel: String? {
        if let linkPaymentDetails {
            return linkPaymentDetails.sublabel
        }
        if isLinkPassthroughMode {
            // We render "Link" as the label, so use the original label
            // as the sublabel.
            return paymentSheetLabel
        }
        return nil
    }
}
