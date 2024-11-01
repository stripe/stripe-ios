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
    func heightDidChange()
    func selectionDidUpdate()
    func presentSavedPaymentMethods(selectedSavedPaymentMethod: STPPaymentMethod?)
}

/// The view for an embedded payment element
class EmbeddedPaymentMethodsView: UIView {

    typealias Selection = VerticalPaymentMethodListSelection // TODO(porter) Maybe define our own later

    private let appearance: PaymentSheet.Appearance
    private let rowButtonAppearance: PaymentSheet.Appearance
    private(set) var selection: Selection? {
        didSet {
            updateMandate()
            if oldValue != selection {
                delegate?.selectionDidUpdate()
            }
        }
    }
    private let mandateProvider: MandateTextProvider
    private let shouldShowMandate: Bool
    /// A bit hacky; this is the mandate text for the given payment method, *regardless* of whether it is shown in the view.
    /// It'd be better if the source of truth of mandate text was not the view and instead an independent `func mandateText(...) -> NSAttributedString` function, but this is hard b/c US Bank Account doesn't show mandate in certain states.
    var mandateText: NSAttributedString? {
        mandateView.attributedText
    }

    private(set) lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = appearance.embeddedPaymentElement.style == .floatingButton ? appearance.embeddedPaymentElement.row.floating.spacing : 0
        return stackView
    }()

    private lazy var mandateView = SimpleMandateTextView(theme: appearance.asElementsTheme)
    private var savedPaymentMethodButton: RowButton?

    weak var delegate: EmbeddedPaymentMethodsViewDelegate?

    init(
        initialSelection: Selection?,
        paymentMethodTypes: [PaymentSheet.PaymentMethodType],
        savedPaymentMethod: STPPaymentMethod?,
        appearance: PaymentSheet.Appearance,
        shouldShowApplePay: Bool,
        shouldShowLink: Bool,
        savedPaymentMethodAccessoryType: RowButton.RightAccessoryButton.AccessoryType?,
        mandateProvider: MandateTextProvider,
        shouldShowMandate: Bool = true,
        delegate: EmbeddedPaymentMethodsViewDelegate? = nil
    ) {
        self.appearance = appearance
        self.mandateProvider = mandateProvider
        self.shouldShowMandate = shouldShowMandate
        self.rowButtonAppearance = appearance.embeddedPaymentElement.style.appearanceForStyle(appearance: appearance)
        self.delegate = delegate
        super.init(frame: .zero)

        if let savedPaymentMethod {
            let selection: Selection = .saved(paymentMethod: savedPaymentMethod)
            let savedPaymentMethodButton = makeSavedPaymentMethodButton(savedPaymentMethod: savedPaymentMethod,
                                                                        savedPaymentMethodAccessoryType: savedPaymentMethodAccessoryType)
            if initialSelection == selection {
                savedPaymentMethodButton.isSelected = true
                self.selection = initialSelection
            }
            self.savedPaymentMethodButton = savedPaymentMethodButton
            stackView.addArrangedSubview(savedPaymentMethodButton)
        }

        // Add card before Apple Pay and Link if present and before any other LPMs
        if paymentMethodTypes.contains(.stripe(.card)) {
            let selection: Selection = .new(paymentMethodType: .stripe(.card))
            let cardRowButton = RowButton.makeForPaymentMethodType(
                paymentMethodType: .stripe(.card),
                savedPaymentMethodType: savedPaymentMethod?.type,
                appearance: rowButtonAppearance,
                shouldAnimateOnPress: true,
                isEmbedded: true,
                didTap: { [weak self] rowButton in
                    self?.didTap(selectedRowButton: rowButton, selection: selection)
                }
            )
            if initialSelection == selection {
                cardRowButton.isSelected = true
                self.selection = initialSelection
            }
            stackView.addArrangedSubview(cardRowButton)
        }

        if shouldShowApplePay {
            let selection: Selection = .applePay
            let applePayRowButton = RowButton.makeForApplePay(appearance: rowButtonAppearance,
                                                              isEmbedded: true,
                                                              didTap: { [weak self] rowButton in
                self?.didTap(selectedRowButton: rowButton, selection: selection)
            })

            if initialSelection == selection {
                applePayRowButton.isSelected = true
                self.selection = initialSelection
            }

            stackView.addArrangedSubview(applePayRowButton)
        }

        if shouldShowLink {
            let selection: Selection = .link
            let linkRowButton = RowButton.makeForLink(appearance: rowButtonAppearance, isEmbedded: true) { [weak self] rowButton in
                self?.didTap(selectedRowButton: rowButton, selection: selection)
            }

            if initialSelection == selection {
                linkRowButton.isSelected = true
                self.selection = initialSelection
            }

            stackView.addArrangedSubview(linkRowButton)
        }

        // Add all non-card PMs (card is added above)
        for paymentMethodType in paymentMethodTypes where paymentMethodType != .stripe(.card) {
            let selection: Selection = .new(paymentMethodType: paymentMethodType)
            let rowButton = RowButton.makeForPaymentMethodType(
                paymentMethodType: paymentMethodType,
                subtitle: VerticalPaymentMethodListViewController.subtitleText(for: paymentMethodType),
                savedPaymentMethodType: savedPaymentMethod?.type,
                appearance: rowButtonAppearance,
                shouldAnimateOnPress: true,
                isEmbedded: true,
                didTap: { [weak self] rowButton in
                    self?.didTap(selectedRowButton: rowButton, selection: selection)
                }
            )
            if initialSelection == selection {
                rowButton.isSelected = true
                self.selection = initialSelection
            }
            stackView.addArrangedSubview(rowButton)
        }

        if appearance.embeddedPaymentElement.style != .floatingButton {
            stackView.addSeparators(color: appearance.embeddedPaymentElement.row.flat.separatorColor ?? appearance.colors.componentBorder,
                                    backgroundColor: appearance.colors.componentBackground,
                                    thickness: appearance.embeddedPaymentElement.row.flat.separatorThickness,
                                    inset: appearance.embeddedPaymentElement.row.flat.separatorInsets ?? appearance.embeddedPaymentElement.style.defaultInsets,
                                    addTopSeparator: appearance.embeddedPaymentElement.row.flat.topSeparatorEnabled,
                                    addBottomSeparator: appearance.embeddedPaymentElement.row.flat.bottomSeparatorEnabled)
        }

        // Setup mandate
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
            delegate?.heightDidChange()
        }
    }

    // MARK: Tap handling
    func didTap(selectedRowButton: RowButton, selection: Selection) {
        for case let rowButton as RowButton in stackView.arrangedSubviews {
            rowButton.isSelected = rowButton === selectedRowButton
        }

        self.selection = selection
    }

    func didTapAccessoryButton() {
        delegate?.presentSavedPaymentMethods(selectedSavedPaymentMethod: selection?.savedPaymentMethod)
    }

    func updateSavedPaymentMethodRow(_ savedPaymentMethod: STPPaymentMethod?,
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

        if let savedPaymentMethod {
            // Replace saved payment method button at same index
            let updatedSavedPaymentMethodButton = makeSavedPaymentMethodButton(savedPaymentMethod: savedPaymentMethod,
                                                                               savedPaymentMethodAccessoryType: accessoryType)
            if isSelected {
                self.stackView.arrangedSubviews.forEach { view in
                    (view as? RowButton)?.isSelected = false
                }
                updatedSavedPaymentMethodButton.isSelected = true
                self.selection = .saved(paymentMethod: savedPaymentMethod)
            }
            // Remove old button & insert new button
            stackView.removeArrangedSubview(previousSavedPaymentMethodButton, animated: false)
            self.stackView.insertArrangedSubview(updatedSavedPaymentMethodButton, at: viewIndex)

            // Update instance states
            self.savedPaymentMethodButton = updatedSavedPaymentMethodButton
        } else {
            // No more saved payment methods
            let separatorIndex = stackView.arrangedSubviews.index(before: viewIndex)
            stackView.removeArrangedSubview(at: separatorIndex, animated: false)
            stackView.removeArrangedSubview(previousSavedPaymentMethodButton, animated: false)

            if case .saved = selection {
                selection = nil
            }

            // Update instance states
            self.savedPaymentMethodButton = nil
        }
    }

    func makeSavedPaymentMethodButton(savedPaymentMethod: STPPaymentMethod,
                                      savedPaymentMethodAccessoryType: RowButton.RightAccessoryButton.AccessoryType?) -> RowButton {
        let accessoryButton: RowButton.RightAccessoryButton? = {
            if let savedPaymentMethodAccessoryType {
                return RowButton.RightAccessoryButton(accessoryType: savedPaymentMethodAccessoryType, appearance: appearance) { [weak self] in
                    self?.didTapAccessoryButton()
                }
            } else {
                return nil
            }
        }()
        let selection: Selection = .saved(paymentMethod: savedPaymentMethod)
        let savedPaymentMethodButton = RowButton.makeForSavedPaymentMethod(paymentMethod: savedPaymentMethod,
                                                                           appearance: rowButtonAppearance,
                                                                           rightAccessoryView: accessoryButton,
                                                                           isEmbedded: true,
                                                                           didTap: { [weak self] rowButton in
           self?.didTap(selectedRowButton: rowButton, selection: selection)
        })
        return savedPaymentMethodButton
    }

    // MARK: Mandate handling
    private func updateMandate(animated: Bool = true) {
        let mandateText = mandateProvider.mandate(
            for: selection?.paymentMethodType,
            savedPaymentMethod: selection?.savedPaymentMethod,
            bottomNoticeAttributedString: nil
        )
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
}

extension PaymentSheet.Appearance.EmbeddedPaymentElement.Style {

    var defaultInsets: UIEdgeInsets {
        switch self {
        case .flatWithRadio:
            return UIEdgeInsets(top: 0, left: 30, bottom: 0, right: 0)
        case .floatingButton:
            return .zero
        }
    }

    fileprivate func appearanceForStyle(appearance: PaymentSheet.Appearance) -> PaymentSheet.Appearance {
        switch self {
        case .flatWithRadio:
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
