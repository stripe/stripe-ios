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
    func buildMandate(for paymentMethodType: PaymentSheet.PaymentMethodType) -> NSAttributedString?
}

// TODO(porter) Probably shouldn't be public, just easy for testing.
@_spi(EmbeddedPaymentElementPrivateBeta) public class EmbeddedPaymentMethodsView: UIView {

    typealias Selection = VerticalPaymentMethodListSelection // TODO(porter) Maybe define our own later

    private let appearance: PaymentSheet.Appearance
    private(set) var selection: Selection?

    lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = appearance.embeddedPaymentElement.style == .floatingButton ? appearance.embeddedPaymentElement.row.floating.spacing : 0
        return stackView
    }()
    
    private lazy var mandateView = { MandateContainerView(appearance: appearance) }()

    // Intentionally not `weak`, EmbeddedPaymentElement does not hold an instance of `EmbeddedPaymentMethodsViewDelegate`
    private var delegate: EmbeddedPaymentMethodsViewDelegate?
    
    init(initialSelection: Selection?,
         paymentMethodTypes: [PaymentSheet.PaymentMethodType],
         savedPaymentMethod: STPPaymentMethod?,
         appearance: PaymentSheet.Appearance,
         shouldShowApplePay: Bool,
         shouldShowLink: Bool,
         savedPaymentMethodAccessoryType: RowButton.RightAccessoryButton.AccessoryType?,
         delegate: EmbeddedPaymentMethodsViewDelegate?) {
        self.appearance = appearance
        self.selection = initialSelection
        self.delegate = delegate
        
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
    private func updateMandate(animated: Bool = true) {
        let theme = appearance.asElementsTheme
        let newMandateText: NSAttributedString? = {
            guard let selectedPaymentMethodType = selection?.paymentMethodType else { return nil }
            if selection?.savedPaymentMethod != nil {
                // 1. For saved PMs, manually build mandates
                switch selectedPaymentMethodType {
                case .stripe(.USBankAccount):
                    return USBankAccountPaymentMethodElement.attributedMandateTextSavedPaymentMethod(alignment: .natural, theme: theme)
                case .stripe(.SEPADebit):
                    return .init(string: String(format: String.Localized.sepa_mandate_text, "TODO merchant name"))
                default:
                    return nil
                }
            } else {
                return delegate?.buildMandate(for: selectedPaymentMethodType)
            }
        }()
            self.mandateView.attributedText = newMandateText
            self.mandateView.setHiddenIfNecessary(newMandateText == nil)
            // TODO(porter) invoke handle on config that height changed
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

class MandateContainerView: UIView {
    private let mandateView: SimpleMandateTextView

    var attributedText: NSAttributedString? {
        get {
            return mandateView.attributedText
        }
        
        set {
            mandateView.attributedText = newValue
        }
    }

    // MARK: - Initializers

    init(appearance: PaymentSheet.Appearance) {
        self.mandateView = SimpleMandateTextView(theme: appearance.asElementsTheme)
        super.init(frame: .zero)
        
        addSubview(mandateView)
        mandateView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            mandateView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: PaymentSheetUI.defaultPadding),
            mandateView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -PaymentSheetUI.defaultPadding),
            mandateView.topAnchor.constraint(equalTo: topAnchor),
            mandateView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
