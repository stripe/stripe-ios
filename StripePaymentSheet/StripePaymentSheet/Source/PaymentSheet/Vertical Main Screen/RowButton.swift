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
    var sublabel: UIView {
        switch sublabelVariant {
        case .plain(let label):
            label
        case .bnpl(let textView, _, _):
            textView
        }
    }
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
    
    // We have two different variants of the row button - a normal one and one that displays BNPL/PMME data
    // The later has some different behavior and uses a different view for the sublabel
    private enum SublabelVariant {
        case plain(UILabel)
        case bnpl(sublabel: UITextView, infoUrl: URL, isExpanded: Bool)
    }

    private var sublabelVariant: SublabelVariant

    var heightConstraint: NSLayoutConstraint?
    let type: RowButtonType
    let shouldAnimateOnPress: Bool
    let appearance: PaymentSheet.Appearance
    let didTap: DidTapClosure
    // When true, this `RowButton` is being used in the embedded payment element, otherwise it is in use in PaymentSheet
    let isEmbedded: Bool

    // MARK: Initializers

    // Plain initializer
    convenience init(
        appearance: PaymentSheet.Appearance,
        type: RowButtonType,
        imageView: UIImageView,
        text: String,
        subtext: String? = nil,
        badgeText: String? = nil,
        promoBadge: PromoBadgeView? = nil,
        accessoryView: UIView? = nil,
        shouldAnimateOnPress: Bool = false,
        isEmbedded: Bool = false,
        didTap: @escaping DidTapClosure
    ) {
        let sublabel = Self.makePlainSublabel(text: subtext, appearance: appearance, isEmbedded: isEmbedded)
        self.init(
            appearance: appearance,
            type: type,
            imageView: imageView,
            text: text,
            sublabel: .plain(sublabel),
            badgeText: badgeText,
            promoBadge: promoBadge,
            accessoryView: accessoryView,
            shouldAnimateOnPress: shouldAnimateOnPress,
            isEmbedded: isEmbedded,
            didTap: didTap
        )
    }
    
    // BNPL/PMME initializer
    convenience init(
        appearance: PaymentSheet.Appearance,
        type: RowButtonType,
        imageView: UIImageView,
        text: String,
        // TODO: We may need to use other data here depending on how we hook up the data from the API. Probably no action needed here.
        bnplPromoText: String,
        bnplLearnMoreText: String,
        bnplInfoUrl: URL,
        badgeText: String? = nil,
        promoBadge: PromoBadgeView? = nil,
        accessoryView: UIView? = nil,
        shouldAnimateOnPress: Bool = false,
        isEmbedded: Bool = false,
        didTap: @escaping DidTapClosure
    ) {
        let sublabel = Self.makeBnplSublabel(appearance: appearance, promotion: bnplPromoText, learnMoreText: bnplLearnMoreText, learnMoreUrl: bnplInfoUrl)
        self.init(
            appearance: appearance,
            type: type,
            imageView: imageView,
            text: text,
            sublabel: .bnpl(sublabel: sublabel, infoUrl: bnplInfoUrl, isExpanded: false),
            badgeText: badgeText,
            promoBadge: promoBadge,
            accessoryView: accessoryView,
            shouldAnimateOnPress: shouldAnimateOnPress,
            isEmbedded: isEmbedded,
            didTap: didTap
        )
        // TODO: Make sure that in the Swift language this code is actually run and the function isn't exited early after the self.init() call. Fix if so.
        sublabel.delegate = self
    }
    
    private init(
        appearance: PaymentSheet.Appearance,
        type: RowButtonType,
        imageView: UIImageView,
        text: String,
        sublabel: SublabelVariant,
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
        self.sublabelVariant = sublabel
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
        guard case .plain(let plainSublabel) = sublabelVariant else {
            stpAssertionFailure("setting the sublabel is not supported in BNPL PMME row type")
            return
        }
        
        guard text != plainSublabel.text else {
            return
        }
        let duration = animated ? 0.2 : 0
        guard let text else {
            UIView.animate(withDuration: duration) { [self] in
                plainSublabel.text = nil
                plainSublabel.isHidden = true
                self.setNeedsLayout()
                self.layoutIfNeeded()
            }
            return
        }
        plainSublabel.text = text
        plainSublabel.alpha = 0
        UIView.animate(withDuration: duration) {
            plainSublabel.isHidden = text.isEmpty
        }
        UIView.animate(withDuration: duration / 2, delay: duration / 2) {
            plainSublabel.alpha = 1
        }
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
        
        if case let .bnpl(sublabelTextView, infoUrl, isExpanded) = sublabelVariant {
            let shouldExpand = isSelected
            // TODO: We should probably find a way to make the semantics clearer here. Kind of confusing to be mixing and matching "isExpanded" and "isSelected" and executing this function in this weird in-between state where isExpanded is out of date. Or maybe not, idk.
            if isExpanded != shouldExpand {
                updateBnplExpansion(isExpanded: shouldExpand)
            }
            
            // Update BNPL info
            sublabelVariant = .bnpl(sublabel: sublabelTextView, infoUrl: infoUrl, isExpanded: shouldExpand)
        }
    }
    
    // TODO: Refactor the duration calculation to not repeat the constant everywhere
    private func updateBnplExpansion(isExpanded: Bool) {
        if isExpanded {
            showBnplInfo()
        } else {
            hideBnplInfo()
        }
    }
    
    // TODO: maybe refactor the call stack of this function so that we don't have to guard on being in the BNPL style. At a minimum clean up the guard
    private func showBnplInfo() {
        guard case let .bnpl(sublabelTextView, _, _) = sublabelVariant else {
            stpAssertionFailure("TODO: put message here")
            return
        }
        heightConstraint?.isActive = false
        sublabelTextView.alpha = 0
        UIView.animate(withDuration: 0.2) {
            sublabelTextView.isHidden = false
            self.setNeedsLayout()
            self.layoutIfNeeded()
        }
        UIView.animate(withDuration: 0.1, delay: 0.1) {
            sublabelTextView.alpha = 1
        }
    }
    
    // TODO: Refactor to be a single function with showBnplInfo, but only if it's clean and readable
    private func hideBnplInfo() {
        guard case let .bnpl(sublabelTextView, _, _) = sublabelVariant else {
            stpAssertionFailure("TODO: put message here")
            return
        }
        UIView.animate(withDuration: 0.2) {
            sublabelTextView.isHidden = true
            self.setNeedsLayout()
            self.layoutIfNeeded()
        }
        UIView.animate(withDuration: 0.2) {
            sublabelTextView.alpha = 0
        }
        makeSameHeightAsOtherRowButtonsIfNecessary()
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
        // To make all RowButtons the same height, set our height to the tallest non-BNPL/PMME variant (a RowButton w/ text and plain subtext)
        
        // The row button is allowed to be taller than the rest and we don't do this if either:
        //      1. We are flat_with_checkmark or flat_with_chevron style and have an accessory view
        //      2. We are the BNPL/PMME variant and are selected (the PMME info is displayed)
        if isFlatWithCheckmarkOrChevronStyle && isDisplayingAccessoryView {
            heightConstraint?.isActive = false
            return
        }
        if case .bnpl = sublabelVariant, isSelected {
            heightConstraint?.isActive = false
            return
        }
        
        // Don't do this if we *are* the tallest variant; otherwise we'll infinite loop!
        if case .plain(let sublabel) = sublabelVariant, sublabel.text?.isEmpty == false {
            heightConstraint?.isActive = false
            return
        }

        heightConstraint = heightAnchor.constraint(equalToConstant: Self.calculateTallestHeight(appearance: appearance, isEmbedded: isEmbedded))
        heightConstraint?.isActive = true
    }
    
    private func openInfoModal() {
        // TODO: We may need to log this being opened. Need to check what we decided on Slack and Google Docs
        
        guard case .bnpl(_, let learnMoreUrl, _) = sublabelVariant else {
            stpAssertionFailure("We should never be trying to open the BNPL info modal outside of BNPL variant")
            return
        }
        
        // TODO: We need to set the style to respect what was passed in PaymentSheet.Configuration. If that is already automatically handled, we can just set the style to the current user interface style, but otherwise we need to add data piping to get the payment sheet configuration or find some other solution.
        let infoController = PMMEInfoModal(infoUrl: learnMoreUrl, style: .alwaysDark)
        infoController.modalPresentationStyle = .formSheet
        // TODO: Let's match how this is done for modals elsewhere in the PaymentSheet (if this exists). I think there are modals that are launched for terms and conditions or mandates or something else.
        window?.findTopMostPresentedViewController()?.present(infoController, animated: true)
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
                       subtext: String? = nil,
                       badgeText: String? = nil,
                       promoBadge: PromoBadgeView? = nil,
                       accessoryView: UIView? = nil,
                       shouldAnimateOnPress: Bool = false,
                       isEmbedded: Bool = false,
                       didTap: @escaping DidTapClosure) -> RowButton {
          // When not using embedded, always use floating style
          if !isEmbedded {
              return RowButtonFloating(
                  appearance: appearance,
                  type: type,
                  imageView: imageView,
                  text: text,
                  subtext: subtext,
                  badgeText: badgeText,
                  promoBadge: promoBadge,
                  accessoryView: accessoryView,
                  shouldAnimateOnPress: shouldAnimateOnPress,
                  isEmbedded: isEmbedded,
                  didTap: didTap
              )
          }

          // If embedded, switch on the style
          switch appearance.embeddedPaymentElement.row.style {
          case .flatWithRadio:
              return RowButtonFlatWithRadioView(
                  appearance: appearance,
                  type: type,
                  imageView: imageView,
                  text: text,
                  subtext: subtext,
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
                  subtext: subtext,
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
                  subtext: subtext,
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
                  subtext: subtext,
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
        let tallestRowButton = RowButton.create(appearance: appearance, type: .new(paymentMethodType: .stripe(.afterpayClearpay)), imageView: imageView, text: "Dummy text", subtext: "Dummy subtext", isEmbedded: isEmbedded) { _ in }
        let size = tallestRowButton.systemLayoutSizeFitting(.init(width: 320, height: UIView.noIntrinsicMetric))
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

    static func makePlainSublabel(text: String?, appearance: PaymentSheet.Appearance, isEmbedded: Bool) -> UILabel {
        let sublabel = UILabel()
        if isEmbedded, let customFont = appearance.embeddedPaymentElement.row.subtitleFont {
            sublabel.font = customFont
        } else {
            sublabel.font = appearance.scaledFont(for: appearance.font.base.regular, style: .caption1, maximumPointSize: 20)
        }
        sublabel.numberOfLines = 1
        sublabel.adjustsFontSizeToFitWidth = true
        sublabel.adjustsFontForContentSizeCategory = true
        sublabel.text = text

        let textColor: UIColor = {
            guard isEmbedded else {
                return appearance.colors.componentPlaceholderText
            }

            switch appearance.embeddedPaymentElement.row.style {
            case .flatWithRadio, .flatWithCheckmark, .flatWithDisclosure:
                return appearance.colors.textSecondary
            case .floatingButton:
                return appearance.colors.componentPlaceholderText
            }
        }()

        sublabel.textColor = textColor
        sublabel.isHidden = text?.isEmpty ?? true
        return sublabel
    }
    
    static func makeBnplSublabel(appearance: PaymentSheet.Appearance, promotion: String, learnMoreText: String, learnMoreUrl: URL) -> UITextView {
        // TODO: we should check the stripe-android code to see how it colors the text in the inline PMME in the PaymentSheet and match the colors from there.
        let textView = PMMEPromotionTextView(foregroundColor: appearance.colors.primary)
        textView.attributedText = NSMutableAttributedString.pmmePromoString(
            font: appearance.scaledFont(for: appearance.font.base.medium, style: .caption1, maximumPointSize: 20),
            textColor: appearance.colors.text,
            template: promotion,
            substitution: nil,
            learnMoreText: learnMoreText,
            learnMoreUrl: learnMoreUrl
        )
        textView.isHidden = true
        textView.alpha = 0
        return textView
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
        currency: String? = nil,
        hasSavedCard: Bool,
        accessoryView: UIView? = nil,
        promoText: String? = nil,
        appearance: PaymentSheet.Appearance,
        originalCornerRadius: CGFloat? = nil,
        shouldAnimateOnPress: Bool,
        isEmbedded: Bool = false,
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
            subtext: subtext,
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
        return RowButton.create(appearance: appearance, type: .applePay, imageView: imageView, text: String.Localized.apple_pay, isEmbedded: isEmbedded, didTap: didTap)
    }

    static func makeForLink(appearance: PaymentSheet.Appearance, isEmbedded: Bool = false, didTap: @escaping DidTapClosure) -> RowButton {
        let imageView = UIImageView(image: Image.link_icon.makeImage())
        imageView.contentMode = .scaleAspectFit
        var subtext = String.Localized.link_subtitle_text
        if let linkAccount = LinkAccountContext.shared.account, linkAccount.isRegistered {
            subtext = linkAccount.email
        }
        let button = RowButton.create(appearance: appearance, type: .link, imageView: imageView, text: STPPaymentMethodType.link.displayName, subtext: subtext, isEmbedded: isEmbedded, didTap: didTap)
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

        let button = RowButton.create(
            appearance: appearance,
            type: .saved(paymentMethod: paymentMethod),
            imageView: imageView,
            text: text,
            subtext: paymentMethod.linkSpecificSublabel ?? subtext,
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

extension RowButton: UITextViewDelegate {
#if !os(visionOS)
    func textView(
        _ textView: UITextView,
        shouldInteractWith URL: URL,
        in characterRange: NSRange,
        interaction: UITextItemInteraction
    ) -> Bool {
        // Only handle a direct tap on the link text.
        // Returning false for other interaction types suppresses previews, edit actions, and other system link affordances.
        guard interaction == .invokeDefaultAction else {
            return false
        }
        
        openInfoModal()
        return false
    }
#endif
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
