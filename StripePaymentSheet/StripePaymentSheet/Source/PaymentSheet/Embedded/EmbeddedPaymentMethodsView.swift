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

// TODO(porter) Probably shouldn't be public, just easy for testing.
@_spi(EmbeddedPaymentMethodsViewBeta) public class EmbeddedPaymentMethodsView: UIView {
    private let appearance: PaymentSheet.Appearance

    lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = appearance.paymentOptionView.style == .floating ? appearance.paymentOptionView.paymentMethodRow.floating.spacing : 0
        return stackView
    }()

    // TODO(porter) Remove later, just for use in EmbeddedPlaygroundViewController since PaymentMethodType and AccessoryType aren't public
    public convenience init(savedPaymentMethod: STPPaymentMethod?,
                            appearance: PaymentSheet.Appearance,
                            shouldShowApplePay: Bool,
                            shouldShowLink: Bool) {
        let paymentMethodTypes: [PaymentSheet.PaymentMethodType] = [.stripe(.bancontact), .stripe(.klarna), .stripe(.card)]
        let savedPaymentMethodAccessoryType: RowButton.RightAccessoryButton.AccessoryType? = .viewMore

        self.init(paymentMethodTypes: paymentMethodTypes, savedPaymentMethod: savedPaymentMethod, appearance: appearance, shouldShowApplePay: shouldShowApplePay, shouldShowLink: shouldShowLink, savedPaymentMethodAccessoryType: savedPaymentMethodAccessoryType)
    }

    init(paymentMethodTypes: [PaymentSheet.PaymentMethodType],
         savedPaymentMethod: STPPaymentMethod?,
         appearance: PaymentSheet.Appearance,
         shouldShowApplePay: Bool,
         shouldShowLink: Bool,
         savedPaymentMethodAccessoryType: RowButton.RightAccessoryButton.AccessoryType?) {
        self.appearance = appearance
        super.init(frame: .zero)
        let rowButtonAppearance = appearance.paymentOptionView.style.appearanceForStyle(appearance: appearance)

        if let savedPaymentMethod {
            let accessoryButton: RowButton.RightAccessoryButton? = {
                if let savedPaymentMethodAccessoryType {
                    return RowButton.RightAccessoryButton(accessoryType: savedPaymentMethodAccessoryType, appearance: appearance, didTap: didTapAccessoryButton)
                } else {
                    return nil
                }
            }()
            stackView.addArrangedSubview(RowButton.makeForSavedPaymentMethod(paymentMethod: savedPaymentMethod,
                                                                             appearance: rowButtonAppearance,
                                                                             rightAccessoryView: accessoryButton,
                                                                             isEmbedded: true,
                                                                             didTap: handleRowSelection(selectedRowButton:)))
        }

        // Add card before Apple Pay and Link if present and before any other LPMs
        if paymentMethodTypes.contains(.stripe(.card)) {
            stackView.addArrangedSubview(RowButton.makeForPaymentMethodType(paymentMethodType: .stripe(.card),
                                                                            savedPaymentMethodType: savedPaymentMethod?.type,
                                                                            appearance: rowButtonAppearance,
                                                                            shouldAnimateOnPress: true,
                                                                            isEmbedded: true,
                                                                            didTap: handleRowSelection(selectedRowButton:)))
        }

        if shouldShowApplePay {
            stackView.addArrangedSubview(RowButton.makeForApplePay(appearance: rowButtonAppearance,
                                                                   isEmbedded: true,
                                                                   didTap: handleRowSelection(selectedRowButton:)))
        }

        if shouldShowLink {
            stackView.addArrangedSubview(RowButton.makeForLink(appearance: rowButtonAppearance,
                                                               isEmbedded: true,
                                                               didTap: handleRowSelection(selectedRowButton:)))
        }

        for paymentMethodType in paymentMethodTypes where paymentMethodType != .stripe(.card) {
            stackView.addArrangedSubview(RowButton.makeForPaymentMethodType(paymentMethodType: paymentMethodType,
                                                                            subtitle: VerticalPaymentMethodListViewController.subtitleText(for: paymentMethodType),
                                                                            savedPaymentMethodType: savedPaymentMethod?.type,
                                                                            appearance: rowButtonAppearance,
                                                                            shouldAnimateOnPress: true,
                                                                            isEmbedded: true,
                                                                            didTap: handleRowSelection(selectedRowButton:)))
        }

        if appearance.paymentOptionView.style != .floating {
            stackView.addSeparators(color: appearance.paymentOptionView.paymentMethodRow.flat.separatorColor ?? appearance.colors.componentBorder,
                                    backgroundColor: appearance.colors.componentBackground,
                                    thickness: appearance.paymentOptionView.paymentMethodRow.flat.separatorThickness,
                                    inset: appearance.paymentOptionView.paymentMethodRow.flat.separatorInset ?? appearance.paymentOptionView.style.defaultInsets,
                                    addTopSeparator: appearance.paymentOptionView.paymentMethodRow.flat.topSeparatorEnabled,
                                    addBottomSeparator: appearance.paymentOptionView.paymentMethodRow.flat.bottomSeparatorEnabled)
        }

        addAndPinSubview(stackView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Tap handling
    func handleRowSelection(selectedRowButton: RowButton) {
        for case let rowButton as RowButton in stackView.arrangedSubviews {
            rowButton.isSelected = rowButton === selectedRowButton
        }
    }

    func didTapAccessoryButton() {
        // TODO(porter)
    }
}

extension PaymentSheet.Appearance.PaymentOptionView.Style {

    var defaultInsets: UIEdgeInsets {
        switch self {
        case .flatRadio:
            return UIEdgeInsets(top: 0, left: 30, bottom: 0, right: 0)
        case .floating:
            return .zero
        }
    }

    fileprivate func appearanceForStyle(appearance: PaymentSheet.Appearance) -> PaymentSheet.Appearance {
        switch self {
        case .flatRadio:
            // TODO(porter) See if there is a better way to do this, less sneaky
            var appearance = appearance
            appearance.borderWidth = 0.0
            appearance.colors.componentBorderSelected = .clear
            appearance.cornerRadius = 0.0
            appearance.shadow = .disabled
            return appearance
        case .floating:
            return appearance
        }
    }
}
