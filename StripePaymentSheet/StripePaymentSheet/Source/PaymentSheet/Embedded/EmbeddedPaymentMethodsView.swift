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

protocol EmbeddedPaymentMethodsViewDelegate: AnyObject {
    func heightDidChange()
}

/// The view for an embedded payment element
class EmbeddedPaymentMethodsView: UIView {

    typealias Selection = VerticalPaymentMethodListSelection // TODO(porter) Maybe define our own later

    private let appearance: PaymentSheet.Appearance
    private(set) var selection: Selection?
    private let mandateProvider: MandateProvider

    lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = appearance.embeddedPaymentElement.style == .floatingButton ? appearance.embeddedPaymentElement.row.floating.spacing : 0
        return stackView
    }()

    private lazy var mandateView = { SimpleMandateContainerView(appearance: appearance) }()

    weak var delegate: EmbeddedPaymentMethodsViewDelegate?

    init(initialSelection: Selection?,
         paymentMethodTypes: [PaymentSheet.PaymentMethodType],
         savedPaymentMethod: STPPaymentMethod?,
         appearance: PaymentSheet.Appearance,
         shouldShowApplePay: Bool,
         shouldShowLink: Bool,
         savedPaymentMethodAccessoryType: RowButton.RightAccessoryButton.AccessoryType?,
         mandateProvider: MandateProvider) {
        self.appearance = appearance
        self.selection = initialSelection
        self.mandateProvider = mandateProvider

        super.init(frame: .zero)
        let rowButtonAppearance = appearance.embeddedPaymentElement.style.appearanceForStyle(appearance: appearance)

        if let savedPaymentMethod {
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

            if initialSelection == selection {
                savedPaymentMethodButton.isSelected = true
            }

            stackView.addArrangedSubview(savedPaymentMethodButton)
        }

        // Add card before Apple Pay and Link if present and before any other LPMs
        if paymentMethodTypes.contains(.stripe(.card)) {
            stackView.addArrangedSubview(RowButton.makeForPaymentMethodType(paymentMethodType: .stripe(.card),
                                                                            savedPaymentMethodType: savedPaymentMethod?.type,
                                                                            appearance: rowButtonAppearance,
                                                                            shouldAnimateOnPress: true,
                                                                            isEmbedded: true,
                                                                            didTap: { [weak self] rowButton in
                self?.didTap(selectedRowButton: rowButton, selection: .new(paymentMethodType: .stripe(.card)))
            }))
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
            }

            stackView.addArrangedSubview(linkRowButton)
        }

        for paymentMethodType in paymentMethodTypes where paymentMethodType != .stripe(.card) {
            stackView.addArrangedSubview(RowButton.makeForPaymentMethodType(paymentMethodType: paymentMethodType,
                                                                            subtitle: VerticalPaymentMethodListViewController.subtitleText(for: paymentMethodType),
                                                                            savedPaymentMethodType: savedPaymentMethod?.type,
                                                                            appearance: rowButtonAppearance,
                                                                            shouldAnimateOnPress: true,
                                                                            isEmbedded: true,
                                                                            didTap: { [weak self] rowButton in
                self?.didTap(selectedRowButton: rowButton, selection: .new(paymentMethodType: paymentMethodType))
            }))
        }

        if appearance.embeddedPaymentElement.style != .floatingButton {
            stackView.addSeparators(color: appearance.embeddedPaymentElement.row.flat.separatorColor ?? appearance.colors.componentBorder,
                                    backgroundColor: appearance.colors.componentBackground,
                                    thickness: appearance.embeddedPaymentElement.row.flat.separatorThickness,
                                    inset: appearance.embeddedPaymentElement.row.flat.separatorInsets ?? appearance.embeddedPaymentElement.style.defaultInsets,
                                    addTopSeparator: appearance.embeddedPaymentElement.row.flat.topSeparatorEnabled,
                                    addBottomSeparator: appearance.embeddedPaymentElement.row.flat.bottomSeparatorEnabled)
        }

        stackView.setCustomSpacing(12.0, after: stackView.arrangedSubviews.last ?? .init(frame: .zero))
        stackView.addArrangedSubview(mandateView)
        addAndPinSubview(stackView)

        updateMandate()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Tap handling
    func didTap(selectedRowButton: RowButton, selection: Selection) {
        for case let rowButton as RowButton in stackView.arrangedSubviews {
            rowButton.isSelected = rowButton === selectedRowButton
        }

        self.selection = selection
        updateMandate()
    }

    func didTapAccessoryButton() {
        // TODO(porter)
    }

    // MARK: Mandate handling
    private func updateMandate() {
        let previousHeight = frame.size.height
        self.mandateView.attributedText = mandateProvider.mandate(for: selection?.paymentMethodType, savedPaymentMethod: selection?.savedPaymentMethod)
        self.mandateView.setHiddenIfNecessary(self.mandateView.attributedText == nil)

        // Force the layout to update so we get the new height
        setNeedsLayout()
        layoutIfNeeded()

        let newHeight = frame.size.height
        if previousHeight != newHeight {
            delegate?.heightDidChange()
        }
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
