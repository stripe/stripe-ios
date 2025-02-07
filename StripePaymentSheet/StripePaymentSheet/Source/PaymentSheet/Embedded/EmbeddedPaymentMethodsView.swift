//
//  EmbeddedPaymentMethodsView.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 8/30/24.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

@MainActor
protocol EmbeddedPaymentMethodsViewDelegate: AnyObject {
    func embeddedPaymentMethodsViewDidUpdateHeight()

    /// Called whenever a payment method row is tapped, after `didUpdateSelection`.
    func embeddedPaymentMethodsViewDidTapPaymentMethodRow()

    /// Called whenever the selection changes
    func embeddedPaymentMethodsViewDidUpdateSelection()

    func embeddedPaymentMethodsViewDidTapViewMoreSavedPaymentMethods(selectedSavedPaymentMethod: STPPaymentMethod?)
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
    private let rowButtonAppearance: PaymentSheet.Appearance
    private let customer: PaymentSheet.CustomerConfiguration?
    private var previousSelectedRowButton: RowButton? {
        didSet {
            guard let previousSelectedRowButton, selectedRowButton?.type != previousSelectedRowButton.type else {
                return
            }
            previousSelectedRowButton.isSelected = false
            // Clear out the 'Change >' button and any sublabel (eg 4242) we set for new PM rows
            switch previousSelectedRowButton.type {
            case .new(paymentMethodType: let paymentMethodType):
                let isCardOrUSBankAccount = paymentMethodType == .stripe(.card) || paymentMethodType == .stripe(.USBankAccount)
                previousSelectedRowButton.removeChangeButton(shouldClearSublabel: isCardOrUSBankAccount)
            default:
               break
            }
        }
    }
    private(set) var selectedRowButton: RowButton? {
        didSet {
            previousSelectedRowButton = oldValue
            if oldValue?.type != selectedRowButton?.type {
                delegate?.embeddedPaymentMethodsViewDidUpdateSelection()
            }
            if let selectedRowButton {
                selectedRowButton.isSelected = true
            }
            updateMandate()
        }
    }
    
    private let mandateProvider: MandateTextProvider
    private let shouldShowMandate: Bool
    private let analyticsHelper: PaymentSheetAnalyticsHelper
    private let incentive: PaymentMethodIncentive?
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

        return SimpleMandateTextView(theme: theme)
    }()
    private var savedPaymentMethodButton: RowButton?
    private(set) var rowButtons: [RowButton]
    weak var delegate: EmbeddedPaymentMethodsViewDelegate?

    init(
        initialSelection: RowButtonType?,
        paymentMethodTypes: [PaymentSheet.PaymentMethodType],
        savedPaymentMethod: STPPaymentMethod?,
        appearance: PaymentSheet.Appearance,
        shouldShowApplePay: Bool,
        shouldShowLink: Bool,
        savedPaymentMethodAccessoryType: RowButton.RightAccessoryButton.AccessoryType?,
        mandateProvider: MandateTextProvider,
        shouldShowMandate: Bool = true,
        savedPaymentMethods: [STPPaymentMethod] = [],
        customer: PaymentSheet.CustomerConfiguration? = nil,
        incentive: PaymentMethodIncentive? = nil,
        analyticsHelper: PaymentSheetAnalyticsHelper,
        delegate: EmbeddedPaymentMethodsViewDelegate? = nil
    ) {
        self.appearance = appearance
        self.mandateProvider = mandateProvider
        self.shouldShowMandate = shouldShowMandate
        self.rowButtonAppearance = appearance.embeddedPaymentElement.row.style.appearanceForStyle(appearance: appearance)
        self.customer = customer
        self.analyticsHelper = analyticsHelper
        self.incentive = incentive
        self.delegate = delegate
        self.rowButtons = []
        super.init(frame: .zero)

        if let savedPaymentMethod {
            let savedPaymentMethodButton = makeSavedPaymentMethodButton(
                savedPaymentMethod: savedPaymentMethod,
                savedPaymentMethodAccessoryType: savedPaymentMethodAccessoryType
            )
            self.savedPaymentMethodButton = savedPaymentMethodButton
            rowButtons.append(savedPaymentMethodButton)
        }

        // Add card before Apple Pay and Link if present and before any other LPMs
        if paymentMethodTypes.contains(.stripe(.card)) {
            let cardRowButton = makePaymentMethodRowButton(
                paymentMethodType: .stripe(.card),
                savedPaymentMethods: savedPaymentMethods
            )
            rowButtons.append(cardRowButton)
        }

        if shouldShowApplePay {
            let applePayRowButton = RowButton.makeForApplePay(appearance: rowButtonAppearance,
                                                              isEmbedded: true,
                                                              didTap: { [weak self] rowButton in
                CustomerPaymentOption.setDefaultPaymentMethod(.applePay, forCustomer: customer?.id)
                self?.didTap(rowButton: rowButton)
            })
            rowButtons.append(applePayRowButton)
        }

        if shouldShowLink {
            let linkRowButton = RowButton.makeForLink(appearance: rowButtonAppearance, isEmbedded: true) { [weak self] rowButton in
                CustomerPaymentOption.setDefaultPaymentMethod(.link, forCustomer: customer?.id)
                self?.didTap(rowButton: rowButton)
            }
            rowButtons.append(linkRowButton)
        }

        // Add all non-card PMs (card is added above)
        for paymentMethodType in paymentMethodTypes where paymentMethodType != .stripe(.card) {
            let rowButton = makePaymentMethodRowButton(
                paymentMethodType: paymentMethodType,
                savedPaymentMethods: savedPaymentMethods
            )
            rowButtons.append(rowButton)
        }
        
        // Add the row buttons to our stack view
        rowButtons.forEach { rowButton in
            stackView.addArrangedSubview(rowButton)
        }

        if appearance.embeddedPaymentElement.row.style != .floatingButton {
            stackView.addSeparators(color: appearance.embeddedPaymentElement.row.flat.separatorColor ?? appearance.colors.componentBorder,
                                    backgroundColor: appearance.colors.componentBackground,
                                    thickness: appearance.embeddedPaymentElement.row.flat.separatorThickness,
                                    inset: appearance.embeddedPaymentElement.row.flat.separatorInsets ?? appearance.embeddedPaymentElement.row.style.defaultInsets,
                                    addTopSeparator: appearance.embeddedPaymentElement.row.flat.topSeparatorEnabled,
                                    addBottomSeparator: appearance.embeddedPaymentElement.row.flat.bottomSeparatorEnabled)
        }

        // If we have a row button that matches the initial selection, make it selected
        if let initialSelection, let rowButtonMatchingInitialSelection = rowButtons.filter({ $0.type == initialSelection }).first {
            rowButtonMatchingInitialSelection.isSelected = true
            self.selectedRowButton = rowButtonMatchingInitialSelection
        }
        
        // Set up mandate
        stackView.addArrangedSubview(mandateView)
        updateMandate(animated: false)

        // Our content should respect `directionalLayoutMargins`. The default margins is `.zero`.
        addAndPinSubview(stackView, directionalLayoutMargins: .zero)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var previousHeight: CGFloat?
    override func layoutSubviews() {
        super.layoutSubviews()

        guard let previousHeight else {
            previousHeight = frame.height
            return
        }

        if frame.height != previousHeight {
            self.previousHeight = frame.height
            delegate?.embeddedPaymentMethodsViewDidUpdateHeight()
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

    // MARK: Tap handling
    func didTap(rowButton: RowButton) {
        self.selectedRowButton = rowButton
        delegate?.embeddedPaymentMethodsViewDidTapPaymentMethodRow()
        analyticsHelper.logNewPaymentMethodSelected(paymentMethodTypeIdentifier: rowButton.type.analyticsIdentifier)

    }

    func didTapViewMoreSavedPaymentMethods() {
        delegate?.embeddedPaymentMethodsViewDidTapViewMoreSavedPaymentMethods(selectedSavedPaymentMethod: selectedRowButton?.type.savedPaymentMethod)
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
                    (view as? RowButton)?.isSelected = false
                }
                updatedSavedPaymentMethodButton.isSelected = true
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
        if let oldCardButton = rowButtons.first(where: { $0.type == .new(paymentMethodType: .stripe(.card))}),
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
    private func updateMandate(animated: Bool = true) {
        let mandateText = mandateProvider.mandate(
            for: selectedRowButton?.type.paymentMethodType,
            savedPaymentMethod: selectedRowButton?.type.savedPaymentMethod,
            bottomNoticeAttributedString: nil
        )
        _updateMandate(mandateText: mandateText, animated: animated)
    }

    private func _updateMandate(mandateText: NSAttributedString?, animated: Bool = true) {
        let shouldDisplayMandate: Bool = {
            guard let mandateText else {
                return false
            }
            return shouldShowMandate && !mandateText.string.isEmpty
        }()
        mandateView.attributedText = mandateText
        let updateMandateUI = {
            let spacing = shouldDisplayMandate ? 12.0 : 0
            guard
                let mandateViewIndex = self.stackView.arrangedSubviews.firstIndex(of: self.mandateView),
                let subviewBeforeMandateView = self.stackView.arrangedSubviews.stp_boundSafeObject(at: mandateViewIndex - 1)
            else {
                stpAssertionFailure()
                return
            }
            self.stackView.setCustomSpacing(spacing, after: subviewBeforeMandateView)
            self.mandateView.setHiddenIfNecessary(!shouldDisplayMandate)
        }
        guard animated else {
            updateMandateUI()
            return
        }
        UIView.animate(withDuration: 0.25, animations: {
            updateMandateUI()
            self.setNeedsLayout()
            self.layoutIfNeeded()
        })
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
            appearance: rowButtonAppearance,
            rightAccessoryView: accessoryButton,
            isEmbedded: true,
            didTap: { [weak self] rowButton in
                CustomerPaymentOption.setDefaultPaymentMethod(
                    .stripeId(savedPaymentMethod.stripeId),
                    forCustomer: self?.customer?.id
                )
                self?.didTap(rowButton: rowButton)
            }
        )
        return savedPaymentMethodButton
    }

    func makePaymentMethodRowButton(paymentMethodType: PaymentSheet.PaymentMethodType, savedPaymentMethods: [STPPaymentMethod]) -> RowButton {
        // We always add a hidden accessory button ("Change >") so we can show/hide it easily
        let accessoryButton = RowButton.RightAccessoryButton(
            accessoryType: appearance.embeddedPaymentElement.row.style == .flatWithCheckmark ? .change : .changeWithChevron,
            appearance: appearance,
            didTap: { [weak self] in
                guard let self, let selectedRowButton else { return }
                didTap(rowButton: selectedRowButton)
            }
        )
        accessoryButton.isHidden = true
        return RowButton.makeForPaymentMethodType(
            paymentMethodType: paymentMethodType,
            hasSavedCard: savedPaymentMethods.hasSavedCard,
            rightAccessoryView: accessoryButton,
            promoText: incentive?.takeIfAppliesTo(paymentMethodType)?.displayText,
            appearance: rowButtonAppearance,
            originalCornerRadius: appearance.cornerRadius,
            shouldAnimateOnPress: true,
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
        case .floatingButton, .flatWithCheckmark:
            return .zero
        }
    }

    fileprivate func appearanceForStyle(appearance: PaymentSheet.Appearance) -> PaymentSheet.Appearance {
        switch self {
        case .flatWithRadio, .flatWithCheckmark:
            // TODO(porter) See if there is a better way to do this, less sneaky
            var appearance = appearance
            appearance.borderWidth = 0.0
            appearance.colors.selectedComponentBorder = .clear
            appearance.cornerRadius = 0.0
            appearance.shadow = .disabled
            return appearance
        case .floatingButton:
            return appearance
        }
    }
}

extension Array where Element == STPPaymentMethod {
    var hasSavedCard: Bool {
        return !self.filter { $0.type == .card }.isEmpty
    }
}

extension RowButton {
    func addChangeButton(sublabel: String?) {
        rightAccessoryView?.isHidden = false
        if let sublabel {
            self.sublabel.text = sublabel
            self.sublabel.isHidden = sublabel.isEmpty
        }
        makeSameHeightAsOtherRowButtonsIfNecessary()
    }
    
    func removeChangeButton(shouldClearSublabel: Bool) {
        rightAccessoryView?.isHidden = true
        if shouldClearSublabel {
            sublabel.text = nil
            sublabel.isHidden = true
        }
    }
}
