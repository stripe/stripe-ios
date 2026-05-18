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
    private var linkBrand: LinkBrand
    private var paymentMethodTypes: [PaymentSheet.PaymentMethodType]
    private let paymentMethodMessagingPromotionsHelper: PaymentMethodMessagingPromotionsHelper?

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
        linkBrand: LinkBrand = .link,
        savedPaymentMethodAccessoryType: RowButton.RightAccessoryButton.AccessoryType?,
        overrideHeaderView: UIView?,
        appearance: PaymentSheet.Appearance,
        currency: String?,
        amount: Int?,
        incentive: PaymentMethodIncentive?,
        paymentMethodMessagingPromotionsHelper: PaymentMethodMessagingPromotionsHelper? = nil,
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
        self.linkBrand = linkBrand
        self.paymentMethodTypes = paymentMethodTypes
        self.paymentMethodMessagingPromotionsHelper = paymentMethodMessagingPromotionsHelper

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
                setRowSelectionState(savedPaymentMethodButton, isSelected: true)
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
                setRowSelectionState(rowButton, isSelected: true)
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
                setRowSelectionState(rowButton, isSelected: true)
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
                setRowSelectionState(rowButton, isSelected: true)
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
        // RowButton is variant-agnostic; the controller casts when it needs to update the plain Link sublabel.
        guard let linkRowButton, let linkRowSublabel = linkRowButton.sublabel as? UILabel else {
            return
        }

        let sublabel = linkAccount?.email ?? .Localized.link_subtitle_text
        linkRowSublabel.setRowButtonPlainSublabelText(sublabel) { [weak linkRowButton] in
            linkRowButton?.didUpdateSublabelLayout()
        }
    }

    // MARK: - Helpers

    func didTap(rowButton: RowButton, selection: RowButtonType) {
        guard let delegate else { return }
        // PMM data is not always available on initial load/display of the RowButton, so we check on tap to see if the data has become available
        populatePaymentMethodMessagingIfAvailable(for: rowButton)
        // We should avoid re-selecting an already selected row to avoid incorrect behavior in the RowButton
        let isRetappingCurrentlySelectedRow = currentSelection == selection && rowButton.isSelected
        // Preserve the existing selected state on repeated taps so BNPL rows don't replay
        // their expand animation just because the same row was tapped again.
        let shouldSelect = delegate.shouldSelectPaymentMethod(selection) && !isRetappingCurrentlySelectedRow
        if shouldSelect {
            // Deselect previous row
            rowButtons.forEach {
                setRowSelectionState($0, isSelected: false)
            }
            // Select new row
            setRowSelectionState(rowButton, isSelected: shouldSelect)
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
        let sublabel = makeSublabel(
            paymentMethodType: paymentMethodType,
            isEmbedded: false
        )
        let rowButton = RowButton.makeForPaymentMethodType(
            paymentMethodType: paymentMethodType,
            currency: currency,
            hasSavedCard: savedPaymentMethods.contains { $0.type == .card },
            sublabel: sublabel,
            promoText: incentive?.takeIfAppliesTo(paymentMethodType)?.displayText,
            appearance: appearance,
            shouldAnimateOnPress: shouldAnimateOnPress,
            didTap: didTap
        )
        configureSublabel(sublabel, for: rowButton)
        return rowButton
    }

    // Temporary prototype/test-only helper.
    // Remove this once saved rows can receive real PMME-backed row content through the production path.
    private func makeSavedPaymentMethodRowButton(
        paymentMethod: STPPaymentMethod,
        accessoryView: UIView?,
        didTap: @escaping RowButton.DidTapClosure
    ) -> RowButton {
        let sublabel = RowButton.makePlainSublabel(
            text: RowButton.makeSavedPaymentMethodPlainSublabelText(
                paymentMethod: paymentMethod,
                linkBrand: linkBrand
            ),
            appearance: appearance,
            isEmbedded: false
        )
        let rowButton = RowButton.makeForSavedPaymentMethod(
            paymentMethod: paymentMethod,
            appearance: appearance,
            sublabel: sublabel,
            accessoryView: accessoryView,
            linkBrand: linkBrand,
            didTap: didTap
        )
        configureSublabel(sublabel, for: rowButton)
        return rowButton
    }

    private func makeApplePayRowButton(didTap: @escaping RowButton.DidTapClosure) -> RowButton {
        let sublabel = RowButton.makePlainSublabel(text: nil, appearance: appearance, isEmbedded: false)
        let rowButton = RowButton.makeForApplePay(appearance: appearance, sublabel: sublabel, didTap: didTap)
        configureSublabel(sublabel, for: rowButton)
        return rowButton
    }

    private func makeLinkRowButton(didTap: @escaping RowButton.DidTapClosure) -> RowButton {
        let sublabel = RowButton.makePlainSublabel(
            text: RowButton.makeLinkPlainSublabelText(),
            appearance: appearance,
            isEmbedded: false
        )
        let rowButton = RowButton.makeForLink(
            appearance: appearance,
            sublabel: sublabel,
            linkBrand: linkBrand,
            didTap: didTap
        )
        configureSublabel(sublabel, for: rowButton)
        return rowButton
    }

    // PMM data is not always available on initial load/display of the RowButton, so we use this to populate PMM content ad hoc
    private func populatePaymentMethodMessagingIfAvailable(for rowButton: RowButton) {
        // RowButton is variant-agnostic; PMME-specific loading happens only when the sublabel is the PMME view.
        guard let sublabel = rowButton.sublabel as? PMMERowSublabelView,
              !sublabel.hasContent,
              let paymentMethodType = rowButton.type.paymentMethodType,
              let content = paymentMethodMessagingPromotionsHelper?.promotion(for: paymentMethodType) else {
            return
        }
        sublabel.populateIfNeeded(content)
    }

    private func configureSublabel(_ sublabel: UIView, for rowButton: RowButton) {
        // Only the PMME sublabel needs to notify the row when expansion changes its layout.
        if let sublabel = sublabel as? PMMERowSublabelView {
            sublabel.onLayoutNeedsUpdate = { [weak rowButton] in
                rowButton?.didUpdateSublabelLayout()
            }
        }
    }

    private func makeSublabel(paymentMethodType: PaymentSheet.PaymentMethodType, isEmbedded: Bool) -> UIView {
        if shouldUsePaymentMethodMessaging(for: paymentMethodType),
           let content = paymentMethodMessagingPromotionsHelper?.promotion(for: paymentMethodType) {
            return PMMERowSublabelView(appearance: appearance, content: content)
        }
        if shouldUsePaymentMethodMessaging(for: paymentMethodType) {
            return PMMERowSublabelView(appearance: appearance, content: nil)
        }
        return RowButton.makePlainSublabel(
            text: RowButton.makePaymentMethodTypePlainSublabelText(paymentMethodType: paymentMethodType, currency: currency),
            appearance: appearance,
            isEmbedded: isEmbedded
        )
    }

    private func shouldUsePaymentMethodMessaging(for paymentMethodType: PaymentSheet.PaymentMethodType) -> Bool {
        guard paymentMethodMessagingPromotionsHelper?.experiment.isInTreatment == true else {
            return false
        }
        switch paymentMethodType {
        case .stripe(.afterpayClearpay), .stripe(.affirm), .stripe(.klarna):
            return true
        default:
            return false
        }
    }

    private func setRowSelectionState(_ rowButton: RowButton, isSelected: Bool) {
        rowButton.isSelected = isSelected
        // RowButton is variant-agnostic; PMME rows still need their sublabel expansion state updated directly.
        (rowButton.sublabel as? PMMERowSublabelView)?.setRowSelected(isSelected)
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
