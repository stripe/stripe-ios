//
//  EmbeddedPaymentMethodsView.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 8/30/24.
//

import Foundation
@_spi(InternalOnlyAPI) import StripeCore
@_spi(InternalOnlyAPI) import StripeUICore
import UIKit

@MainActor
protocol EmbeddedPaymentMethodsViewDelegate: AnyObject {
    func embeddedPaymentMethodsViewDidUpdateHeight()

    /// Called before the view changes its selected row.
    func embeddedPaymentMethodsViewWillSelect(_ rowButtonType: RowButtonType)

    /// Called whenever a payment method row is tapped, after `didUpdateSelection`.
    func embeddedPaymentMethodsViewDidTapPaymentMethodRow()

    /// Called whenever the selection changes
    func embeddedPaymentMethodsViewDidUpdateSelection()

    func embeddedPaymentMethodsViewDidTapViewMoreSavedPaymentMethods(selectedSavedPaymentMethod: STPPaymentMethod?)

    /// Determines if selecting the given row button type will cause a form to be displayed.
    /// - Parameter rowButtonType: The type of row button being evaluated.
    /// - Returns: True if selecting this row button type will display a form.
    func willDisplayForm(for rowButtonType: RowButtonType?) -> Bool

    /// The mandate for the Link payment details the selected Link row shows, if any.
    func embeddedPaymentMethodsViewLinkMandateText() -> NSAttributedString?
}

extension EmbeddedPaymentMethodsViewDelegate {
    func embeddedPaymentMethodsViewLinkMandateText() -> NSAttributedString? { nil }
}

/// The view for an embedded payment element
class EmbeddedPaymentMethodsView: UIView {
    /// Return the default size to let Auto Layout manage the height.
    /// Overriding intrinsicContentSize values and setting `invalidIntrinsicContentSize` forces force SwiftUI to update layout immediately,
    /// resulting in abrupt, non-animated height changes.
    override var intrinsicContentSize: CGSize {
        return super.intrinsicContentSize
    }

    private let appearance: PaymentSheet.Appearance
    private let currency: String?
    private let paymentMethodMessagingPromotionsHelper: PaymentMethodMessagingPromotionsHelper?
    private let featuredInstitutionsLoader: FeaturedInstitutionsLoader?
    private(set) var previousSelectedRowButton: RowButton? {
        didSet {
            guard let previousSelectedRowButton, selectedRowButton?.type != previousSelectedRowButton.type else {
                return
            }
            previousSelectedRowButton.updateSelectedState(false, willDisplayForm: delegate?.willDisplayForm(for: selectedRowButton?.type) == true)
            // Clear out the 'Change >' button and any sublabel (eg 4242) we set for new PM rows
            switch previousSelectedRowButton.type {
            case .new(paymentMethodType: let paymentMethodType):
                let isCardOrUSBankAccount = paymentMethodType == .stripe(.card) || paymentMethodType == .stripe(.USBankAccount)
                previousSelectedRowButton.removeChangeButton(shouldClearSublabel: isCardOrUSBankAccount)
            case .link where previousSelectedRowButton.accessoryView != nil:
                // The Link row goes back to showing the customer's email instead of the payment details they picked.
                previousSelectedRowButton.removeChangeButton(shouldClearSublabel: false)
                updateLinkRow(for: LinkAccountContext.shared.account, animated: false)
            default:
               break
            }
        }
    }
    private(set) var selectedRowButton: RowButton? {
        didSet {
            previousSelectedRowButton = oldValue
            let selectedRowButtonTypeDidChange = oldValue?.type != selectedRowButton?.type
            updateMandate()
            if selectedRowButtonTypeDidChange {
                selectedRowChangeButtonState = nil
                delegate?.embeddedPaymentMethodsViewDidUpdateSelection()
            }
            if let selectedRowButton {
                selectedRowButton.updateSelectedState(true, willDisplayForm: delegate?.willDisplayForm(for: selectedRowButton.type) == true)
            }
        }
    }
    private var linkRowButton: RowButton? {
        rowButtons.first(where: { $0.type == .link })
    }

    private let mandateProvider: MandateTextProvider
    private let shouldShowMandate: Bool
    private let analyticsHelper: PaymentSheetAnalyticsHelper
    private let incentive: PaymentMethodIncentive?
    private var linkBrand: LinkBrand
    private let linkBrandProvider: () -> LinkBrand
    /// A bit hacky; this is the mandate text for the given payment method, *regardless* of whether it is shown in the view.
    /// It'd be better if the source of truth of mandate text was not the view and instead an independent `func mandateText(...) -> NSAttributedString` function, but this is hard b/c US Bank Account doesn't show mandate in certain states.
    var mandateText: NSAttributedString? {
        mandateView.attributedText
    }
    private(set) lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = appearance.embeddedPaymentElement.row.style == .floatingButton ? appearance.embeddedPaymentElement.row.floating.spacing : 0
        return stackView
    }()
    private lazy var mandateView = {
        // Special font size for mandates in embedded
        var theme = appearance.asElementsTheme
        theme.fonts.caption = appearance.scaledFont(for: appearance.font.base.regular, style: .caption2, maximumPointSize: 20)
        let mandateView = SimpleMandateTextView(theme: theme)
        // Add some padding so that we can hide/remove it from the stackview without fiddling with padding in there.
        mandateView.directionalLayoutMargins.top = 12
        return mandateView
    }()
    lazy var errorLabel = ElementsUI.makeErrorLabel(theme: appearance.asElementsTheme)
    private lazy var errorContainerView: UIView = {
        let view = UIView()
        view.addAndPinSubview(
            errorLabel,
            directionalLayoutMargins: .init(top: 12, leading: 0, bottom: 0, trailing: 0)
        )
        view.setHiddenIfNecessary(true)
        return view
    }()
    private var savedPaymentMethodButton: RowButton?
    /// The expanded Link row, shown in place of the Link row while a returning Link customer can verify inline.
    private(set) var linkInlineVerificationView: EmbeddedLinkInlineVerificationView?
    private var linkInlineVerificationContainer: UIView?
    /// The separators around the expanded Link row, hidden while it shows since it has its own border.
    private(set) var linkInlineVerificationHiddenSeparators: [UIView] = []
    private(set) var rowButtons: [RowButton]
    /// Whether the Link row, showing the Link payment details it pays with, is the only row.
    let showsOnlyLink: Bool
    weak var delegate: EmbeddedPaymentMethodsViewDelegate?
    /// Keeps track of whether we're showing a change button/sublabel on the selected row
    /// Hacky - ideally we have a RowButtonViewModel type of object that keeps track of this state.
    var selectedRowChangeButtonState: (shouldShowChangeButton: Bool, sublabel: String?)?

    init(
        initialSelectedRowType: RowButtonType?,
        initialSelectedRowChangeButtonState: (shouldShowChangeButton: Bool, sublabel: String?)?,
        paymentMethodTypes: [PaymentSheet.PaymentMethodType],
        savedPaymentMethod: STPPaymentMethod?,
        appearance: PaymentSheet.Appearance,
        shouldShowApplePay: Bool,
        shouldShowLink: Bool,
        linkBrand: LinkBrand = .link,
        linkBrandProvider: (() -> LinkBrand)? = nil,
        placesLinkFirst: Bool = false,
        linkInlineVerificationView: EmbeddedLinkInlineVerificationView? = nil,
        linkOnlyPaymentDetails: ConsumerPaymentDetails? = nil,
        savedPaymentMethodAccessoryType: RowButton.RightAccessoryButton.AccessoryType?,
        mandateProvider: MandateTextProvider,
        shouldShowMandate: Bool = true,
        savedPaymentMethods: [STPPaymentMethod] = [],
        currency: String? = nil,
        incentive: PaymentMethodIncentive? = nil,
        paymentMethodMessagingPromotionsHelper: PaymentMethodMessagingPromotionsHelper? = nil,
        featuredInstitutionsLoader: FeaturedInstitutionsLoader? = nil,
        analyticsHelper: PaymentSheetAnalyticsHelper,
        delegate: EmbeddedPaymentMethodsViewDelegate? = nil
    ) {
        self.appearance = appearance
        self.mandateProvider = mandateProvider
        self.shouldShowMandate = shouldShowMandate
        self.currency = currency
        self.paymentMethodMessagingPromotionsHelper = paymentMethodMessagingPromotionsHelper
        self.featuredInstitutionsLoader = featuredInstitutionsLoader
        self.analyticsHelper = analyticsHelper
        self.incentive = incentive
        self.linkBrand = linkBrand
        self.linkBrandProvider = linkBrandProvider ?? { linkBrand }
        self.delegate = delegate
        self.rowButtons = []
        // After inline verification selects Link payment details, Link is the only row until the customer pays another way.
        let showsOnlyLink = shouldShowLink && linkOnlyPaymentDetails != nil
        self.showsOnlyLink = showsOnlyLink
        super.init(frame: .zero)

        let makeLinkRowButton = { [weak self] in
            RowButton.makeForLink(
                appearance: appearance,
                linkBrand: linkBrand,
                isEmbedded: true,
                // After inline verification, the Link row shows the payment details picked in the Link wallet and a "Change" button.
                accessoryView: placesLinkFirst ? self?.makeChangeButton() : nil
            ) { rowButton in
                self?.didTap(rowButton: rowButton)
            }
        }

        if showsOnlyLink, let linkOnlyPaymentDetails {
            rowButtons.append(RowButton.makeForLinkPaymentDetails(
                linkOnlyPaymentDetails,
                appearance: appearance,
                linkBrand: linkBrand,
                isEmbedded: true,
                accessoryView: makeLinkOnlyAccessoryButton(linkBrand: linkBrand)
            ) { [weak self] rowButton in
                self?.didTap(rowButton: rowButton)
            })
        }

        // Link leads for returning Link customers who can verify inline, and keeps its place afterwards.
        if shouldShowLink, placesLinkFirst, !showsOnlyLink {
            rowButtons.append(makeLinkRowButton())
        }

        if let savedPaymentMethod, !showsOnlyLink {
            let savedPaymentMethodButton = makeSavedPaymentMethodButton(
                savedPaymentMethod: savedPaymentMethod,
                savedPaymentMethodAccessoryType: savedPaymentMethodAccessoryType
            )
            self.savedPaymentMethodButton = savedPaymentMethodButton
            rowButtons.append(savedPaymentMethodButton)
        }

        // Add card before Apple Pay and Link if present and before any other LPMs
        if paymentMethodTypes.contains(.stripe(.card)), !showsOnlyLink {
            let cardRowButton = makePaymentMethodRowButton(
                paymentMethodType: .stripe(.card),
                savedPaymentMethods: savedPaymentMethods
            )
            rowButtons.append(cardRowButton)
        }

        if shouldShowApplePay, !showsOnlyLink {
            let applePayRowButton = RowButton.makeForApplePay(appearance: appearance,
                                                              isEmbedded: true,
                                                              didTap: { [weak self] rowButton in
                self?.didTap(rowButton: rowButton)
            })
            rowButtons.append(applePayRowButton)
        }

        if shouldShowLink, !placesLinkFirst, !showsOnlyLink {
            rowButtons.append(makeLinkRowButton())
        }

        // Add all non-card PMs (card is added above)
        for paymentMethodType in paymentMethodTypes where paymentMethodType != .stripe(.card) && !showsOnlyLink {
            let rowButton = makePaymentMethodRowButton(
                paymentMethodType: paymentMethodType,
                savedPaymentMethods: savedPaymentMethods
            )
            rowButtons.append(rowButton)
        }

        // Add the row buttons to our stack view
        rowButtons.forEach { rowButton in
            if showsOnlyLink, appearance.embeddedPaymentElement.row.style != .floatingButton {
                // Like the inline verification card it replaces, the Link-only row sits in its own container instead of between separators.
                stackView.addArrangedSubview(LinkOnlyRowContainerView(rowButton: rowButton, appearance: appearance))
            } else {
                stackView.addArrangedSubview(rowButton)
            }
        }

        if appearance.embeddedPaymentElement.row.style != .floatingButton, !showsOnlyLink {
            stackView.addSeparators(color: appearance.embeddedPaymentElement.row.flat.separatorColor ?? appearance.colors.componentBorder,
                                    thickness: appearance.embeddedPaymentElement.row.flat.separatorThickness,
                                    inset: appearance.embeddedPaymentElement.row.flat.separatorInsets ?? appearance.embeddedPaymentElement.row.style.defaultInsets,
                                    addTopSeparator: appearance.embeddedPaymentElement.row.flat.topSeparatorEnabled,
                                    addBottomSeparator: appearance.embeddedPaymentElement.row.flat.bottomSeparatorEnabled)
        }

        // Inserted after the separators so they stay between rows.
        if let linkInlineVerificationView, let linkRowButton, let linkRowIndex = stackView.arrangedSubviews.firstIndex(of: linkRowButton) {
            let container = UIView()
            // Flat rows sit flush against their separators, so give the card room around it.
            let verticalInset: CGFloat = appearance.embeddedPaymentElement.row.style == .floatingButton ? 0 : 8
            container.addAndPinSubview(linkInlineVerificationView, insets: .insets(top: verticalInset, bottom: verticalInset))
            stackView.insertArrangedSubview(container, at: linkRowIndex + 1)
            linkRowButton.setHiddenIfNecessary(true)
            // The separator before the hidden Link row and the one after the card.
            linkInlineVerificationHiddenSeparators = [linkRowIndex - 1, linkRowIndex + 2]
                .filter { stackView.arrangedSubviews.indices.contains($0) }
                .map { stackView.arrangedSubviews[$0] }
                .filter { !($0 is RowButton) }
            linkInlineVerificationHiddenSeparators.forEach { $0.setHiddenIfNecessary(true) }
            self.linkInlineVerificationView = linkInlineVerificationView
            self.linkInlineVerificationContainer = container
        }

        // If we have a row button that matches the initial selection, make it selected
        if let initialSelectedRowType, let rowButtonMatchingInitialSelection = rowButtons.filter({ $0.type == initialSelectedRowType }).first {
            rowButtonMatchingInitialSelection.updateSelectedState(true, willDisplayForm: delegate?.willDisplayForm(for: rowButtonMatchingInitialSelection.type) == true)
            // The Link-only row already shows its payment details.
            if let initialSelectedRowChangeButtonState, !showsOnlyLink {
                selectedRowChangeButtonState = initialSelectedRowChangeButtonState
                if initialSelectedRowChangeButtonState.shouldShowChangeButton {
                    rowButtonMatchingInitialSelection.addChangeButton(animated: false)
                    rowButtonMatchingInitialSelection.setSublabel(text: initialSelectedRowChangeButtonState.sublabel, animated: false)
                }
            }
            self.selectedRowButton = rowButtonMatchingInitialSelection
        }

        // Set up mandate
        stackView.addArrangedSubview(mandateView)
        updateMandate(animated: false)
        stackView.addArrangedSubview(errorContainerView)

        // Our content should respect `directionalLayoutMargins`. The default margins is `.zero`.
        addAndPinSubview(stackView, directionalLayoutMargins: .zero)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        // Just to make sure no observer stays around
        LinkAccountContext.shared.removeObserver(self)
    }

    private func logInitialDisplayedPaymentMethods() {
        // The user has to scroll through all the payment method options before checking out, so all of the lpms are visible
        let visiblePaymentMethods: [String] = rowButtons.filter { !$0.type.isSaved }.compactMap { $0.type.analyticsIdentifier }
        let hiddenPaymentMethods: [String] = []
        analyticsHelper.logInitialDisplayedPaymentMethods(visiblePaymentMethods: visiblePaymentMethods, hiddenPaymentMethods: hiddenPaymentMethods)
    }

    private var previousHeight: CGFloat?
    var notifiesDelegateOnInitialHeight = false
    private var didLogRenderLPMs: Bool = false
    override func layoutSubviews() {
        super.layoutSubviews()

        // Only log this once, and not for the Link-only list, which isn't the list of payment methods the customer can pick from.
        if !didLogRenderLPMs, !showsOnlyLink {
            logInitialDisplayedPaymentMethods()
            didLogRenderLPMs = true
        }

        // Calculate our natural height
        let desiredHeight = systemLayoutSizeFitting(CGSize(width: frame.width, height: UIView.layoutFittingExpandedSize.height)).height

        // If we never recorded a height, this is our first layout.
        guard let previousHeight else {
            previousHeight = desiredHeight
            if notifiesDelegateOnInitialHeight {
                delegate?.embeddedPaymentMethodsViewDidUpdateHeight()
            }
            return
        }

        // If the desired height is different from our last recorded, notify the delegate that our height is updating.
        if desiredHeight != previousHeight {
            self.previousHeight = desiredHeight
            delegate?.embeddedPaymentMethodsViewDidUpdateHeight()
        }
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()

        if window != nil {
            if linkRowButton != nil {
                initializeLinkAccountObserver()
            }
        } else {
            LinkAccountContext.shared.removeObserver(self)
        }
    }

    private func initializeLinkAccountObserver() {
        LinkAccountContext.shared.addObserver(self, selector: #selector(onLinkAccountChange(_:)))

        if let linkAccount = LinkAccountContext.shared.account, linkAccount.isRegistered {
            updateLinkRow(for: linkAccount, animated: false)
        }
    }

    // MARK: Internal functions

    /// If the customer cancels out of a form, restore the last selected payment method row
    func resetSelectionToLastSelection() {
        selectedRowButton = previousSelectedRowButton
    }

    func resetSelection() {
        selectedRowButton = nil
    }

    /// Selects the Link row if it's displayed.
    @discardableResult
    func selectLinkRow() -> Bool {
        guard let linkRowButton else { return false }
        selectedRowButton = linkRowButton
        return true
    }

    /// Shows the Link row loading and blocks taps, e.g. while the element works out which Link payment details to select.
    func setLinkRowLoading(_ loading: Bool, animated: Bool = true) {
        isUserInteractionEnabled = !loading
        linkRowButton?.setLoading(loading, animated: animated)
    }

    /// Replaces the expanded Link row with the regular Link row, which keeps its position.
    func collapseLinkInlineVerification(animated: Bool = true) {
        guard let container = linkInlineVerificationContainer else { return }
        linkInlineVerificationContainer = nil
        linkInlineVerificationView = nil
        let linkRowButton = linkRowButton
        let separators = linkInlineVerificationHiddenSeparators
        linkInlineVerificationHiddenSeparators = []
        defer { UIAccessibility.post(notification: .layoutChanged, argument: linkRowButton) }

        guard animated, window != nil, !UIAccessibility.isReduceMotionEnabled, let linkRowButton else {
            container.removeFromSuperview()
            separators.forEach { $0.setHiddenIfNecessary(false) }
            linkRowButton?.setHiddenIfNecessary(false)
            return
        }

        // Shrinking the card inside the stack view squashes its content over the rows below, so the card leaves the
        // stack view and is clipped from its top edge down to the Link row, fading out over the Link row as it fades in.
        layoutIfNeeded()
        let containerFrame = container.frame
        let linkRowIndex = stackView.arrangedSubviews.firstIndex(of: linkRowButton) ?? 0
        let separatorBefore = separators.first { (stackView.arrangedSubviews.firstIndex(of: $0) ?? 0) < linkRowIndex }
        let separatorAfter = separators.first { (stackView.arrangedSubviews.firstIndex(of: $0) ?? 0) > linkRowIndex }
        let clipView = UIView(frame: container.convert(container.bounds, to: self))
        clipView.clipsToBounds = true
        clipView.isUserInteractionEnabled = false
        container.removeFromSuperview()
        container.translatesAutoresizingMaskIntoConstraints = true
        container.autoresizingMask = []
        container.frame = clipView.bounds
        clipView.addSubview(container)
        addSubview(clipView)

        separators.forEach { $0.setHiddenIfNecessary(false) }
        linkRowButton.setHiddenIfNecessary(false)
        linkRowButton.alpha = 0
        // Hidden views keep stale frames, so start them where they'd be now instead of animating from there.
        UIView.performWithoutAnimation {
            let width = stackView.bounds.width
            var y = containerFrame.minY
            if let separatorBefore {
                separatorBefore.frame = CGRect(x: 0, y: y, width: width, height: separatorBefore.intrinsicHeight(width: width))
                separatorBefore.layoutIfNeeded()
                y = separatorBefore.frame.maxY
            }
            linkRowButton.frame = CGRect(x: 0, y: y, width: width, height: linkRowButton.intrinsicHeight(width: width))
            linkRowButton.layoutIfNeeded()
            if let separatorAfter {
                separatorAfter.frame = CGRect(x: 0, y: containerFrame.maxY, width: width, height: separatorAfter.intrinsicHeight(width: width))
                separatorAfter.layoutIfNeeded()
            }
        }

        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut) {
            self.setNeedsLayout()
            self.layoutIfNeeded()
            let linkRowFrame = linkRowButton.convert(linkRowButton.bounds, to: self)
            clipView.frame.size.height = max(0, linkRowFrame.maxY - clipView.frame.minY)
        } completion: { _ in
            clipView.removeFromSuperview()
        }
        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseOut) {
            clipView.alpha = 0
        }
        UIView.animate(withDuration: 0.2, delay: 0.1, options: .curveEaseIn) {
            linkRowButton.alpha = 1
        }
    }

    /// Displays an error below the payment method rows, or clears it when `error` is nil.
    func setError(_ error: Error?, animated: Bool = true) {
        let message = error?.nonGenericDescription
        guard message != errorLabel.text else { return }
        errorLabel.text = message
        let updates = {
            self.errorContainerView.setHiddenIfNecessary(message == nil)
            self.setNeedsLayout()
            self.layoutIfNeeded()
        }
        if animated {
            UIView.animate(withDuration: PaymentSheetUI.defaultAnimationDuration, animations: updates)
        } else {
            updates()
        }
        if message != nil {
            UIAccessibility.post(notification: .layoutChanged, argument: errorLabel)
        }
    }

    /// Selects the saved payment method if it is still displayed.
    func selectSavedPaymentMethod(withStripeId stripeId: String) -> Bool {
        guard let rowButton = rowButtons.first(where: {
            $0.type.savedPaymentMethod?.stripeId == stripeId
        }) else { return false }
        selectedRowButton = rowButton
        return true
    }

    @objc
    func onLinkAccountChange(_ notification: Notification) {
        DispatchQueue.main.async { [weak self] in
            let linkAccount = notification.object as? PaymentSheetLinkAccount
            self?.updateLinkRow(for: linkAccount)
        }
    }

    // MARK: Tap handling
    func didTap(rowButton: RowButton) {
        setError(nil)
        delegate?.embeddedPaymentMethodsViewWillSelect(rowButton.type)
        self.selectedRowButton = rowButton
        delegate?.embeddedPaymentMethodsViewDidTapPaymentMethodRow()
        analyticsHelper.logNewPaymentMethodSelected(paymentMethodTypeIdentifier: rowButton.type.analyticsIdentifier)

    }

    func didTapViewMoreSavedPaymentMethods() {
        setError(nil)
        delegate?.embeddedPaymentMethodsViewDidTapViewMoreSavedPaymentMethods(selectedSavedPaymentMethod: selectedRowButton?.type.savedPaymentMethod)
    }

    func updateLinkRow(for linkAccount: PaymentSheetLinkAccount?, animated: Bool = true) {
        // The Link-only row shows its payment details instead of the account.
        guard let linkRowButton, !showsOnlyLink else {
            return
        }

        let resolvedBrand = linkBrandProvider()
        if resolvedBrand != linkBrand {
            linkBrand = resolvedBrand
            linkRowButton.setLabel(text: resolvedBrand.displayName)
            linkRowButton.setPrimaryAccessibilityLabel(
                resolvedBrand.accessibilityText(from: String.Localized.pay_with_link(brand: resolvedBrand))
            )
        }

        var sublabel = String.Localized.link_subtitle_text

        if let linkAccount, linkAccount.isRegistered {
            sublabel = linkAccount.email
        }

        // A selected Link row shows the payment details picked in the Link wallet instead.
        if selectedRowButton === linkRowButton, let selectedSublabel = selectedRowChangeButtonState?.sublabel {
            sublabel = selectedSublabel
        }

        linkRowButton.setSublabel(text: sublabel, animated: animated)
    }

    func updateSavedPaymentMethodRow(_ savedPaymentMethods: [STPPaymentMethod],
                                     isSelected: Bool,
                                     accessoryType: RowButton.RightAccessoryButton.AccessoryType?) {
        guard let previousSavedPaymentMethodButton = self.savedPaymentMethodButton,
              let viewIndex = stackView.arrangedSubviews.firstIndex(of: previousSavedPaymentMethodButton) else {
            stpAssertionFailure("""
            This function should never be called when there isn't already a saved PM row because there's no way for Embedded
            to add a saved payment method today; you can only update or remove them.
            """)
            return
        }

        if let savedPaymentMethod = savedPaymentMethods.first {
            // Replace saved payment method button at same index
            let updatedSavedPaymentMethodButton = makeSavedPaymentMethodButton(savedPaymentMethod: savedPaymentMethod,
                                                                               savedPaymentMethodAccessoryType: accessoryType)
            if isSelected {
                self.stackView.arrangedSubviews.forEach { view in
                    if let rowButton = view as? RowButton {
                        rowButton.updateSelectedState(false, willDisplayForm: delegate?.willDisplayForm(for: rowButton.type) == true)
                    }
                }
                updatedSavedPaymentMethodButton.updateSelectedState(true, willDisplayForm: delegate?.willDisplayForm(for: updatedSavedPaymentMethodButton.type) == true)
                self.selectedRowButton = updatedSavedPaymentMethodButton
            }
            // Remove old button & insert new button
            stackView.removeArrangedSubview(previousSavedPaymentMethodButton, animated: false)
            stackView.insertArrangedSubview(updatedSavedPaymentMethodButton, at: viewIndex)

            // Update instance states
            self.savedPaymentMethodButton = updatedSavedPaymentMethodButton
            rowButtons.replace(previousSavedPaymentMethodButton, with: updatedSavedPaymentMethodButton)
        } else {
            // No more saved payment methods
            let separatorIndex = stackView.arrangedSubviews.index(before: viewIndex)
            if separatorIndex >= 0 {
                stackView.removeArrangedSubview(at: separatorIndex, animated: false)
            }
            stackView.removeArrangedSubview(previousSavedPaymentMethodButton, animated: false)

            if case .saved = selectedRowButton?.type {
                selectedRowButton = nil
            }

            // Update instance states
            self.savedPaymentMethodButton = nil
            self.rowButtons.remove(previousSavedPaymentMethodButton)
        }

        // Update text on card row based on the new selected payment method
        // It can vary between "Card" if the customer has no saved cards or "New card" if the customer has saved cards
        if let oldCardButton = rowButtons.first(where: { $0.type == .new(paymentMethodType: .stripe(.card)) }),
           let oldCardButtonIndex = stackView.arrangedSubviews.firstIndex(of: oldCardButton) {
            // Update selectionButtonMapping and add this new one to the stack view and remove old card row
            let cardRowButton = makePaymentMethodRowButton(
                paymentMethodType: .stripe(.card),
                savedPaymentMethods: savedPaymentMethods
            )
            // TODO: Pass in the selection state (eg selectedWithChangeButton) so it's retained

            // Replace row button
            stackView.removeArrangedSubview(oldCardButton, animated: false)
            stackView.insertArrangedSubview(cardRowButton, at: oldCardButtonIndex)
            rowButtons.replace(oldCardButton, with: cardRowButton)
        }
    }

    // MARK: Mandate handling
    func updateMandate(animated: Bool = true) {
        let mandateText: NSAttributedString? = if selectedRowButton?.type == .link {
            delegate?.embeddedPaymentMethodsViewLinkMandateText()
        } else {
            mandateProvider.mandate(
                for: selectedRowButton?.type.paymentMethodType,
                savedPaymentMethod: selectedRowButton?.type.savedPaymentMethod,
                bottomNoticeAttributedString: nil
            )
        }
        _updateMandate(mandateText: mandateText, animated: animated)
    }

    private func _updateMandate(mandateText: NSAttributedString?, animated: Bool = true) {
        let shouldDisplayMandate: Bool = if let mandateText {
            shouldShowMandate && !mandateText.string.isEmpty
        } else {
            false
        }
        guard animated else {
            self.mandateView.attributedText = mandateText
            self.mandateView.setHiddenIfNecessary(!shouldDisplayMandate)
            return
        }
        switch (mandateView.isHidden, shouldDisplayMandate) {
        case (true, true): // Hidden -> Showing mandate
            UIView.animate(withDuration: 0.25) {
                self.mandateView.attributedText = mandateText
                // Un-hide mandate
                self.mandateView.setHiddenIfNecessary(!shouldDisplayMandate)
                self.setNeedsLayout()
                self.layoutIfNeeded()
            }

            // Fade it in slightly after
            self.mandateView.alpha = 0
            UIView.animate(withDuration: 0.2, delay: 0.15) {
                self.mandateView.alpha = 1
            }
        case (false, false): // Showing mandate -> Hidden
            UIView.animate(withDuration: 0.25) {
                self.mandateView.attributedText = mandateText
                // Hide the mandate
                self.mandateView.setHiddenIfNecessary(true)
                self.setNeedsLayout()
                self.layoutIfNeeded()
            }
        case (false, true): // Showing mandate -> Showing mandate
            UIView.transition(with: self.mandateView, duration: 0.25, options: .transitionCrossDissolve) {
                self.mandateView.attributedText = mandateText
                self.setNeedsLayout()
                self.layoutIfNeeded()
            }
        case (true, false): // Hidden -> Hidden
            // Update mandate text on the view so the payment option we vend to the merchant has the correct mandate
            self.mandateView.attributedText = mandateText
        }
    }

#if DEBUG
    func testHeightChange() {
        if self.mandateView.isHidden {
            let testMandateString = "This is an example of a long string that may appear based on selecting a payment method that has a mandate. Please ensure that your view can properly adapt to height changes by calling testHeightChange() on embedded payment element and manually verify that your view responds well to height changes"
            let formattedString = NSMutableAttributedString(string: testMandateString)
            let style = NSMutableParagraphStyle()
            style.alignment = .left
            formattedString.addAttributes([.paragraphStyle: style,
                                           .font: UIFont.preferredFont(forTextStyle: .footnote),
                                           .foregroundColor: appearance.asElementsTheme.colors.secondaryText,
            ],
                                          range: NSRange(location: 0, length: formattedString.length))

            _updateMandate(mandateText: formattedString)
        } else {
            _updateMandate(mandateText: nil)
        }
    }
#endif
    // MARK: - Helpers

    func makeSavedPaymentMethodButton(savedPaymentMethod: STPPaymentMethod,
                                      savedPaymentMethodAccessoryType: RowButton.RightAccessoryButton.AccessoryType?) -> RowButton {
        let accessoryButton: RowButton.RightAccessoryButton? = {
            if let savedPaymentMethodAccessoryType {
                return RowButton.RightAccessoryButton(accessoryType: savedPaymentMethodAccessoryType, appearance: appearance) { [weak self] in
                    self?.didTapViewMoreSavedPaymentMethods()
                }
            } else {
                return nil
            }
        }()
        let savedPaymentMethodButton = RowButton.makeForSavedPaymentMethod(
            paymentMethod: savedPaymentMethod,
            appearance: appearance,
            accessoryView: accessoryButton,
            isEmbedded: true,
            linkBrand: linkBrand,
            didTap: { [weak self] rowButton in
                self?.didTap(rowButton: rowButton)
            }
        )
        return savedPaymentMethodButton
    }

    /// A hidden "Change >" button, which re-taps the selected row.
    func makeChangeButton() -> RowButton.RightAccessoryButton {
        let accessoryButton = RowButton.RightAccessoryButton(
            accessoryType: appearance.embeddedPaymentElement.row.style.omitChevronInAccessoryButton ? .change : .changeWithChevron,
            appearance: appearance,
            didTap: { [weak self] in
                guard let self, let selectedRowButton else { return }
                didTap(rowButton: selectedRowButton)
            }
        )
        accessoryButton.isHidden = true
        return accessoryButton
    }

    /// The Link logo and a chevron on the Link-only row. Tapping it changes the Link payment details, like tapping the row.
    private func makeLinkOnlyAccessoryButton(linkBrand: LinkBrand) -> RowButton.RightAccessoryButton {
        RowButton.RightAccessoryButton(
            accessoryType: .link(brand: linkBrand),
            appearance: appearance,
            didTap: { [weak self] in
                guard let self, let linkRowButton else { return }
                didTap(rowButton: linkRowButton)
            }
        )
    }

    func makePaymentMethodRowButton(paymentMethodType: PaymentSheet.PaymentMethodType, savedPaymentMethods: [STPPaymentMethod]) -> RowButton {
        // We always add a hidden accessory button ("Change >") so we can show/hide it easily
        return RowButton.makeForPaymentMethodType(
            paymentMethodType: paymentMethodType,
            currency: currency,
            hasSavedCard: savedPaymentMethods.hasSavedCard,
            accessoryView: makeChangeButton(),
            promoText: incentive?.takeIfAppliesTo(paymentMethodType)?.displayText,
            promotionsHelper: paymentMethodMessagingPromotionsHelper,
            featuredInstitutionsLoader: featuredInstitutionsLoader,
            appearance: appearance,
            originalCornerRadius: appearance.cornerRadius,
            shouldAnimateOnPress: delegate?.willDisplayForm(for: .new(paymentMethodType: paymentMethodType)) == true,
            isEmbedded: true,
            didTap: { [weak self] rowButton in
                self?.didTap(rowButton: rowButton)
            }
        )
    }
}

extension PaymentSheet.Appearance.EmbeddedPaymentElement.Row.Style {

    var defaultInsets: UIEdgeInsets {
        switch self {
        case .flatWithRadio:
            return UIEdgeInsets(top: 0, left: 30, bottom: 0, right: 0)
        case .floatingButton, .flatWithCheckmark, .flatWithDisclosure:
            return .zero
        }
    }
}

extension Array where Element == STPPaymentMethod {
    var hasSavedCard: Bool {
        return !self.filter { $0.type == .card }.isEmpty
    }
}

extension RowButton {
    func addChangeButton(animated: Bool = true) {
        // Hack: We assume the accessory view is "Change >"
        self.accessoryView?.isHidden = false
        // The "Change" button replaces the featured bank icons once a bank is linked
        bankInstitutionIconsView?.isSuppressed = true
        makeSameHeightAsOtherRowButtonsIfNecessary()
        guard animated else {
            self.accessoryView?.alpha = 1
            return
        }
        self.setNeedsLayout()
        self.layoutIfNeeded()
        self.accessoryView?.alpha = 0
        UIView.animate(withDuration: 0.2) {
            self.accessoryView?.alpha = 1
        }
    }

    func removeChangeButton(shouldClearSublabel: Bool) {
        // Hack: We assume the accessory view is "Change >"
        self.accessoryView?.isHidden = true
        bankInstitutionIconsView?.isSuppressed = false
        self.setNeedsLayout()
        self.layoutIfNeeded()
        if shouldClearSublabel {
            setSublabel(text: nil)
        }
    }
}

/// Borders the Link-only row in flat styles, the same way as the inline verification card. Floating rows draw their own.
private final class LinkOnlyRowContainerView: UIView {
    private let appearance: PaymentSheet.Appearance

    init(rowButton: RowButton, appearance: PaymentSheet.Appearance) {
        self.appearance = appearance
        super.init(frame: .zero)
        layer.borderWidth = max(appearance.borderWidth, 1)
        layer.borderColor = appearance.colors.componentBorder.cgColor
        applyCornerRadiusOrConfiguration(for: appearance)
        // Lines the row's icon and accessory up with the card's 16pt padding. Radio rows have no trailing padding of their own.
        let trailingInset: CGFloat = appearance.embeddedPaymentElement.row.style == .flatWithRadio ? 16 : 4
        addAndPinSubview(rowButton, insets: .insets(leading: 4, trailing: trailingInset))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        // `CGColor` doesn't follow light and dark mode on its own.
        layer.borderColor = appearance.colors.componentBorder.cgColor
    }
}

private extension UIView {
    func intrinsicHeight(width: CGFloat) -> CGFloat {
        systemLayoutSizeFitting(
            CGSize(width: width, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        ).height
    }
}
