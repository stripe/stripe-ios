//
//  VerticalPaymentMethodListViewController.swift
//  StripePaymentSheet
//
//  Created by Yuki Tokuhiro on 5/20/24.
//

@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripeUICore
import UIKit

// MARK: - VerticalPaymentMethodListViewController
/// A simple container VC for the VerticalPaymentMethodListView, which displays payment options in a vertical list.
class VerticalPaymentMethodListViewController: UIViewController {
    // Temporary prototype/test-only values for forcing the BNPL row variant in vertical mode.
    // Remove all of this prototype wiring once PMME-backed row data is wired through the real integration path.
    private static let forcePrototypeBNPLStyleForAllRows = true
    private static let forcedBNPLLearnMoreText = "Learn more"
    private static let forcedBNPLInfoURL = URL(string: "https://www.lego.com")!

    /// Returns the number of row buttons in the vertical list
    var rowCount: Int {
        return rowButtons.count
    }
    var rowButtons: [RowButton] {
        return stackView.arrangedSubviews.compactMap { $0 as? RowButton }
    }
    private var linkRowButton: RowButton? {
        rowButtons.first(where: { $0.type == .link })
    }
    private(set) var currentSelection: RowButtonType?
    let stackView = UIStackView()
    let appearance: PaymentSheet.Appearance
    let currency: String?
    private(set) var incentive: PaymentMethodIncentive?
    weak var delegate: VerticalPaymentMethodListViewControllerDelegate?

    // Properties moved from initializer captures
    private var overrideHeaderView: UIView?
    private var savedPaymentMethods: [STPPaymentMethod]
    private var initialSelection: RowButtonType?
    private var savedPaymentMethodAccessoryType: RowButton.RightAccessoryButton.AccessoryType?
    private var shouldShowApplePay: Bool
    private var shouldShowLink: Bool
    private var paymentMethodTypes: [PaymentSheet.PaymentMethodType]

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func clearSelection() {
        currentSelection = nil
        initialSelection = nil
        refreshContent()
    }

    init(
        initialSelection: RowButtonType?,
        savedPaymentMethods: [STPPaymentMethod],
        paymentMethodTypes: [PaymentSheet.PaymentMethodType],
        shouldShowApplePay: Bool,
        shouldShowLink: Bool,
        savedPaymentMethodAccessoryType: RowButton.RightAccessoryButton.AccessoryType?,
        overrideHeaderView: UIView?,
        appearance: PaymentSheet.Appearance,
        currency: String?,
        amount: Int?,
        incentive: PaymentMethodIncentive?,
        delegate: VerticalPaymentMethodListViewControllerDelegate
    ) {
        self.appearance = appearance
        self.currency = currency
        self.incentive = incentive
        self.delegate = delegate
        self.overrideHeaderView = overrideHeaderView
        self.savedPaymentMethods = savedPaymentMethods
        self.initialSelection = initialSelection
        self.savedPaymentMethodAccessoryType = savedPaymentMethodAccessoryType
        self.shouldShowApplePay = shouldShowApplePay
        self.shouldShowLink = shouldShowLink
        self.paymentMethodTypes = paymentMethodTypes

        super.init(nibName: nil, bundle: nil)
        self.renderContent()
    }

    private func refreshContent() {
        stackView.arrangedSubviews.forEach { subview in
            subview.removeFromSuperview()
        }

        renderContent()
    }

    private func renderContent() {
        // Add the header - either the passed in `header` or "Select payment method"
        let header = overrideHeaderView ?? PaymentSheetUI.makeHeaderLabel(title: .Localized.select_payment_method, appearance: appearance)
        stackView.addArrangedSubview(header)
        stackView.setCustomSpacing(24, after: header)

        // Create stack view views after super.init so that we can reference `self`
        var views = [UIView]()
        // Saved payment method:
        if let firstSavedPaymentMethod = savedPaymentMethods.first {
            let selection = RowButtonType.saved(paymentMethod: firstSavedPaymentMethod)
            let accessoryButton: RowButton.RightAccessoryButton? = {
                if let savedPaymentMethodAccessoryType {
                    return RowButton.RightAccessoryButton(accessoryType: savedPaymentMethodAccessoryType, appearance: appearance, didTap: didTapAccessoryButton)
                } else {
                    return nil
                }
            }()

            let savedPaymentMethodButton = makeSavedPaymentMethodRowButton(
                paymentMethod: firstSavedPaymentMethod,
                accessoryView: accessoryButton
            ) { [weak self] in
                self?.didTap(rowButton: $0, selection: selection)
            }
            if initialSelection == selection {
                savedPaymentMethodButton.isSelected = true
                currentSelection = selection
            }
            views += [
                Self.makeSectionLabel(text: .Localized.saved, appearance: appearance),
                savedPaymentMethodButton,
                .makeSpacerView(height: 12),
                Self.makeSectionLabel(text: .Localized.new_payment_method, appearance: appearance),
            ]
        }

        // Build Apple Pay and Link rows
        let applePay: RowButton? = {
            guard shouldShowApplePay else { return nil }
            let selection = RowButtonType.applePay
            let rowButton = makeApplePayRowButton { [weak self] in
                self?.didTap(rowButton: $0, selection: .applePay)
            }
            if initialSelection == selection {
                rowButton.isSelected = true
                currentSelection = selection
            }
            return rowButton
        }()
        let link: RowButton? = {
            guard shouldShowLink else { return nil }
            let selection = RowButtonType.link
            let rowButton = makeLinkRowButton { [weak self] in
                self?.didTap(rowButton: $0, selection: .link)
            }
            if initialSelection == selection {
                rowButton.isSelected = true
                currentSelection = selection
            }
            return rowButton
        }()

        // Payment methods
        var indexAfterCards: Int?
        let paymentMethodTypes = paymentMethodTypes
        for paymentMethodType in paymentMethodTypes {
            let selection = RowButtonType.new(paymentMethodType: paymentMethodType)
            let rowButton = makeRowButton(
                paymentMethodType: paymentMethodType,
                // Enable press animation if tapping this transitions the screen to a form instead of becoming selected
                shouldAnimateOnPress: delegate?.shouldSelectPaymentMethod(selection) == false
            ) { [weak self] in
                self?.didTap(rowButton: $0, selection: selection)
            }
            views.append(rowButton)
            if paymentMethodType == .stripe(.card), let index = views.firstIndex(of: rowButton) {
                indexAfterCards = index + 1
            }
            if initialSelection == selection {
                rowButton.isSelected = true
                currentSelection = selection
            }
        }

        // Insert Apple Pay/Link after card or, if cards aren't present, first
        views.insert(contentsOf: [applePay, link].compactMap({ $0 }), at: indexAfterCards ?? 0)

        for view in views {
            stackView.addArrangedSubview(view)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        stackView.axis = .vertical
        stackView.spacing = 12.0
        view = stackView
        view.backgroundColor = appearance.colors.background

        if linkRowButton != nil {
            initializeLinkAccountObserver()
        }
    }

    deinit {
        LinkAccountContext.shared.removeObserver(self)
    }

    private func initializeLinkAccountObserver() {
        LinkAccountContext.shared.addObserver(self, selector: #selector(onLinkAccountChange(_:)))

        if let linkAccount = LinkAccountContext.shared.account, linkAccount.isRegistered {
            updateLinkRow(for: linkAccount)
        }
    }

    @objc
    func onLinkAccountChange(_ notification: Notification) {
        DispatchQueue.main.async { [weak self] in
            let linkAccount = notification.object as? PaymentSheetLinkAccount
            self?.updateLinkRow(for: linkAccount)
        }
    }

    private func updateLinkRow(for linkAccount: PaymentSheetLinkAccount?) {
        guard !Self.forcePrototypeBNPLStyleForAllRows else {
            return
        }
        guard let linkRowButton else {
            return
        }

        let sublabel = linkAccount?.email ?? .Localized.link_subtitle_text
        linkRowButton.setSublabel(text: sublabel)
    }

    // MARK: - Helpers

    func didTap(rowButton: RowButton, selection: RowButtonType) {
        guard let delegate else { return }
        let isRetappingCurrentlySelectedRow = currentSelection == selection && rowButton.isSelected
        // Preserve the existing selected state on repeated taps so BNPL rows don't replay
        // their expand animation just because the same row was tapped again.
        let shouldSelect = delegate.shouldSelectPaymentMethod(selection) && !isRetappingCurrentlySelectedRow
        if shouldSelect {
            // Deselect previous row
            rowButtons.forEach {
                $0.isSelected = false
            }
            // Select new row
            rowButton.isSelected = shouldSelect
            currentSelection = selection
        }
        delegate.didTapPaymentMethod(selection)
        return
    }

    @objc func didTapAccessoryButton() {
        delegate?.didTapSavedPaymentMethodAccessoryButton()
    }

    func setIncentive(_ incentive: PaymentMethodIncentive?) {
        guard self.incentive != incentive else {
            return
        }

        self.incentive = incentive
        self.refreshContent()
    }

    private func makeRowButton(
        paymentMethodType: PaymentSheet.PaymentMethodType,
        shouldAnimateOnPress: Bool,
        didTap: @escaping RowButton.DidTapClosure
    ) -> RowButton {
        if let rowButton = makePrototypeBNPLRowButton(
            type: .new(paymentMethodType: paymentMethodType),
            paymentMethodType: paymentMethodType,
            text: paymentMethodButtonText(for: paymentMethodType),
            accessoryView: nil,
            badgeText: nil,
            promoBadge: makePromoBadge(for: paymentMethodType),
            shouldAnimateOnPress: shouldAnimateOnPress,
            didTap: didTap
        ) {
            return rowButton
        }

        return RowButton.makeForPaymentMethodType(
            paymentMethodType: paymentMethodType,
            currency: currency,
            hasSavedCard: savedPaymentMethods.contains { $0.type == .card },
            promoText: incentive?.takeIfAppliesTo(paymentMethodType)?.displayText,
            appearance: appearance,
            shouldAnimateOnPress: shouldAnimateOnPress,
            didTap: didTap
        )
    }

    // Temporary prototype/test-only helper.
    // Remove this once saved rows can receive real PMME-backed row content through the production path.
    private func makeSavedPaymentMethodRowButton(
        paymentMethod: STPPaymentMethod,
        accessoryView: UIView?,
        didTap: @escaping RowButton.DidTapClosure
    ) -> RowButton {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        let savedPaymentMethodRowImage = paymentMethod.makeSavedPaymentMethodRowImage(iconStyle: appearance.iconStyle)
        imageView.image = savedPaymentMethodRowImage

        let text = paymentMethod.isLinkPassthroughMode
            ? STPPaymentMethodType.link.displayName
            : paymentMethod.paymentSheetLabel

        if let rowButton = makePrototypeBNPLRowButton(
            type: .saved(paymentMethod: paymentMethod),
            paymentMethodType: .stripe(paymentMethod.type),
            imageView: imageView,
            text: text,
            accessoryView: accessoryView,
            badgeText: nil,
            promoBadge: nil,
            shouldAnimateOnPress: false,
            didTap: didTap
        ) {
            return rowButton
        }

        return RowButton.makeForSavedPaymentMethod(
            paymentMethod: paymentMethod,
            appearance: appearance,
            accessoryView: accessoryView,
            didTap: didTap
        )
    }

    // Temporary prototype/test-only helper.
    // Remove this once wallet rows can receive real PMME-backed row content through the production path.
    private func makeApplePayRowButton(didTap: @escaping RowButton.DidTapClosure) -> RowButton {
        let imageView = UIImageView(image: Image.apple_pay_mark.makeImage())
        imageView.contentMode = .scaleAspectFit

        if let rowButton = makePrototypeBNPLRowButton(
            type: .applePay,
            paymentMethodType: nil,
            imageView: imageView,
            text: "Apple Pay",
            accessoryView: nil,
            badgeText: nil,
            promoBadge: nil,
            shouldAnimateOnPress: false,
            didTap: didTap
        ) {
            return rowButton
        }

        return RowButton.makeForApplePay(appearance: appearance, didTap: didTap)
    }

    // Temporary prototype/test-only helper.
    // Remove this once wallet rows can receive real PMME-backed row content through the production path.
    private func makeLinkRowButton(didTap: @escaping RowButton.DidTapClosure) -> RowButton {
        let imageView = UIImageView(image: Image.link_icon.makeImage())
        imageView.contentMode = .scaleAspectFit

        if let rowButton = makePrototypeBNPLRowButton(
            type: .link,
            paymentMethodType: nil,
            imageView: imageView,
            text: STPPaymentMethodType.link.displayName,
            accessoryView: nil,
            badgeText: nil,
            promoBadge: nil,
            shouldAnimateOnPress: false,
            didTap: didTap
        ) {
            return rowButton
        }

        return RowButton.makeForLink(appearance: appearance, didTap: didTap)
    }

    private func paymentMethodButtonText(for paymentMethodType: PaymentSheet.PaymentMethodType) -> String {
        if savedPaymentMethods.contains(where: { $0.type == .card }) && paymentMethodType == .stripe(.card) {
            return .Localized.new_card
        }
        return paymentMethodType.displayName
    }

    private func makePromoBadge(for paymentMethodType: PaymentSheet.PaymentMethodType) -> PromoBadgeView? {
        guard let promoText = incentive?.takeIfAppliesTo(paymentMethodType)?.displayText else {
            return nil
        }
        return PromoBadgeView(
            appearance: appearance,
            cornerRadius: nil,
            tinyMode: false,
            text: promoText
        )
    }

    // Temporary prototype/test-only hook to force the BNPL row variant from a higher level than RowButton.
    // Remove this entire helper once PMME-backed row data is plumbed through the real production path.
    private func makePrototypeBNPLRowButton(
        type: RowButtonType,
        paymentMethodType: PaymentSheet.PaymentMethodType?,
        imageView: UIImageView? = nil,
        text: String,
        accessoryView: UIView?,
        badgeText: String?,
        promoBadge: PromoBadgeView?,
        shouldAnimateOnPress: Bool,
        didTap: @escaping RowButton.DidTapClosure
    ) -> RowButton? {
        guard Self.forcePrototypeBNPLStyleForAllRows else {
            return nil
        }

        let imageView = imageView ?? {
            guard let paymentMethodType else {
                return UIImageView()
            }
            let imageView = PaymentMethodTypeImageView(
                paymentMethodType: paymentMethodType,
                contrastMatchingColor: appearance.colors.componentText,
                currency: currency,
                iconStyle: appearance.iconStyle
            )
            imageView.contentMode = .scaleAspectFit
            return imageView
        }()

        return RowButtonFloating(
            appearance: appearance,
            type: type,
            imageView: imageView,
            text: text,
            bnplPromoText: forcedBNPLPromoText(for: paymentMethodType),
            bnplLearnMoreText: Self.forcedBNPLLearnMoreText,
            bnplInfoUrl: Self.forcedBNPLInfoURL,
            badgeText: badgeText,
            promoBadge: promoBadge,
            accessoryView: accessoryView,
            shouldAnimateOnPress: shouldAnimateOnPress,
            didTap: didTap
        )
    }

    // Temporary prototype/test-only copy source used by the forced BNPL row variant.
    // Remove this once real PMME copy is passed down through the production path.
    private func forcedBNPLPromoText(for paymentMethodType: PaymentSheet.PaymentMethodType?) -> String {
        switch paymentMethodType {
        case .stripe(.klarna)?:
            return String.Localized.buy_now_or_pay_later_with_klarna
        case .stripe(.afterpayClearpay)?:
            if AfterpayPriceBreakdownView.shouldUseClearpayBrand(for: currency) {
                return String.Localized.buy_now_or_pay_later_with_clearpay
            } else if AfterpayPriceBreakdownView.shouldUseCashAppBrand(for: currency) {
                return String.Localized.buy_now_or_pay_later_with_cash_app_afterpay
            } else {
                return String.Localized.buy_now_or_pay_later_with_afterpay
            }
        case .stripe(.affirm)?:
            return String.Localized.pay_over_time_with_affirm
        default:
            return "Prototype BNPL messaging"
        }
    }

    static func makeSectionLabel(text: String, appearance: PaymentSheet.Appearance) -> UILabel {
        let label = UILabel()
        label.font = appearance.scaledFont(for: appearance.font.base.regular, style: .subheadline, maximumPointSize: 25)
        label.textColor = appearance.colors.text
        label.adjustsFontForContentSizeCategory = true
        label.text = text
        return label
    }
}

// MARK: - VerticalPaymentMethodListViewControllerDelegate
protocol VerticalPaymentMethodListViewControllerDelegate: AnyObject {
    /// Called when a row is tapped, before `didTapPaymentMethod` is called.
    /// - Returns: Whether or not the payment method row button should appear selected.
    func shouldSelectPaymentMethod(_ selection: RowButtonType) -> Bool

    /// Called after a row is tapped and after `shouldSelectPaymentMethod` is called
    func didTapPaymentMethod(_ selection: RowButtonType)

    /// Called when the accessory button on the saved payment method row is tapped
    func didTapSavedPaymentMethodAccessoryButton()
}
