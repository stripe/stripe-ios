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

    private var paymentOptionView: PaymentSheet.Appearance.PaymentOptionView {
        guard let paymentOptionView = appearance.paymentOptionView else {
            stpAssert(false, "appearance.paymentOptionView cannot be nil when using EmbeddedPaymentMethodsView.")
            return .init()
        }

        return paymentOptionView
    }

    lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = paymentOptionView.style == .floating ? paymentOptionView.paymentMethodRow.spacing : 0
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
        let rowButtonAppearance = paymentOptionView.style.appearanceForStyle(appearance: appearance)

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
                                                                             didTap: handleRowSelection(selectedRowButton:)))
        }

        // Add card before Apple Pay and Link if present and before any other LPMs
        if paymentMethodTypes.contains(.stripe(.card)) {
            stackView.addArrangedSubview(RowButton.makeForPaymentMethodType(paymentMethodType: .stripe(.card),
                                                                            savedPaymentMethodType: savedPaymentMethod?.type,
                                                                            appearance: rowButtonAppearance,
                                                                            shouldAnimateOnPress: true,
                                                                            didTap: handleRowSelection(selectedRowButton:)))
        }

        if shouldShowApplePay {
            stackView.addArrangedSubview(RowButton.makeForApplePay(appearance: rowButtonAppearance,
                                                                   didTap: handleRowSelection(selectedRowButton:)))
        }

        if shouldShowLink {
            stackView.addArrangedSubview(RowButton.makeForLink(appearance: rowButtonAppearance,
                                                               didTap: handleRowSelection(selectedRowButton:)))
        }

        for paymentMethodType in paymentMethodTypes where paymentMethodType != .stripe(.card) {
            stackView.addArrangedSubview(RowButton.makeForPaymentMethodType(paymentMethodType: paymentMethodType,
                                                                            savedPaymentMethodType: savedPaymentMethod?.type,
                                                                            appearance: rowButtonAppearance,
                                                                            shouldAnimateOnPress: true,
                                                                            didTap: handleRowSelection(selectedRowButton:)))
        }

        if paymentOptionView.style != .floating {
            stackView.addSeparators(color: paymentOptionView.paymentMethodRow.flat.separatorColor ?? appearance.colors.componentBorder,
                                    thickness: paymentOptionView.paymentMethodRow.flat.separatorThickness,
                                    inset: paymentOptionView.paymentMethodRow.flat.separatorInset ?? paymentOptionView.style.defaultInsets,
                                    addTopSeparator: paymentOptionView.paymentMethodRow.flat.topSeparatorEnabled,
                                    addBottomSeparator: paymentOptionView.paymentMethodRow.flat.bottomSeparatorEnabled)
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
        case .flatCheck, .floating:
            return .zero
        }
    }

    func appearanceForStyle(appearance: PaymentSheet.Appearance) -> PaymentSheet.Appearance {
        switch self {
        case .flatRadio, .flatCheck:
            // TODO(porter) See if there is a better way to do this, less sneaky
            var appearance = appearance
            appearance.borderWidth = 0.0
            appearance.cornerRadius = 0.0
            appearance.shadow = .disabled
            return appearance
        case .floating:
            return appearance
        }
    }
}
